open Core
open Async
open Marshal
open Random

(** Wire protocol: either a message or an acknowledgement *)
type packet = Message of { id : int; message : string } | Ack of { id : int }

(** Encode a packet for sending over the wire *)
let encode packet : string = Base64.encode_exn (to_string packet [])

(** Decode a packet that was received over the wire *)
let decode encoded : packet = from_string (Base64.decode_exn encoded) 0

(** Get the current time in milliseconds *)
let nowMs () : float = Unix.gettimeofday () *. Float.of_int 1000

(** A buffer of lines, read from stdin, to send as chat messages *)
let stdin_queue = Queue.create ()

(** A reference to stdin, to be read continuously *)
let stdin = Lazy.force Reader.stdin

(** Continuously read from stdin, and save contents in stdin_queue. *)
let rec read_stdin () =
  let%bind line = Reader.read_line stdin in
  match line with
  | `Eof -> read_stdin ()
  | `Ok line ->
      Queue.enqueue stdin_queue line;
      read_stdin ()

(** The main chat loop:

  * When we have messages in stdin_queue to send, send them.
    * Keep track of message creation times for measuring acks

  * When we receive messages or acks, print them
    * Clean up old acks after measuring and printing them

  * Not implemented: error reporting when receiving an unknown ack
*)
let chat reader writer =
  ignore (Queue.clear stdin_queue);
  let acks = Hashtbl.create (module Int) in

  (*
    The "speak loop":

    * Send any queued lines over the wire as messages, keeping track of
      when they were sent in the `acks` cache
    * If there's nothing queued, wait 100ms before checking again

    This could be improved by using a blocking queue to wait for new
    messages to send.
  *)
  let rec speak () =
    (*
      Check that the socket is still open before we try to send a
      message over it.  It would be better if we could just cancel the
      whole `Deferred` instance upon connection loss.
    *)
    if Writer.is_closed writer then return ()
    else
      match Queue.dequeue stdin_queue with
      | None -> Clock.after (sec 0.1) >>= fun _ -> speak ()
      | Some line ->
          let id = bits () in
          let now = nowMs () in
          ignore (Hashtbl.add acks ~key:id ~data:now);
          let packet = Message { id; message = line } in
          let encoded : string = encode packet in
          Writer.write_line writer encoded;
          speak ()
  in

  (*
    The "listen loop":

    * Wait for a message or ack
    * When a message is received, print it
    * When an ack is received, measure the time, print it, and remove it
      from the `acks` cache
  *)
  let rec listen () =
    let%bind line = Reader.read_line reader in
    match line with
    | `Eof ->
        printf "Remote disconnected.\n";
        return ()
    | `Ok encoded -> (
        match decode encoded with
        | Message { id; message } ->
            printf "<remote> %s\n" message;
            Writer.write_line writer (encode (Ack { id }));
            listen ()
        | Ack { id } ->
            let showAck start : unit =
              let finish = nowMs () in
              let ackTime = finish -. start in
              printf "ack: %.2fms\n" ackTime
            in
            let ack = Hashtbl.find acks id in
            ignore (Option.iter ~f:showAck ack);
            ignore (Hashtbl.remove acks id);
            listen ())
  in
  Deferred.any [ speak (); listen () ]

(** Start the chat app in server mode *)
let start_server port =
  let%bind server =
    Tcp.Server.create ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port port) (fun _ reader writer ->
        printf "Client connected.\n";
        chat reader writer)
  in
  Tcp.Server.close_finished server

(** Start the chat app in client mode *)
let start_client host port =
  Tcp.with_connection
    (Tcp.Where_to_connect.of_host_and_port { host; port })
    (fun _ reader writer ->
      printf "Connected to %s.\n" host;
      chat reader writer)

let () =
  ignore (read_stdin ());
  Command.async ~summary:"Start a chat server or client"
    (let%map_open.Command host =
       flag "-host" (optional string) ~doc:" Host to connect to"
     in
     fun () ->
       let port = 1337 in
       match host with
       | None ->
           printf "Waiting for client to connect.\n";
           start_server port
       | Some host -> start_client host port)
  |> Command_unix.run
