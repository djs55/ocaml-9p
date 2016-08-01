(*
 * Copyright (C) 2015 David Scott <dave.scott@unikernel.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Lwt

type 'a io = 'a Lwt.t

type buffer = Cstruct.t

type error = Unix.error

let error_message = Unix.error_message

type flow = {
  fd: Lwt_unix.file_descr;
  read_buffer_size: int;
  mutable read_buffer: Cstruct.t;
  mutable closed: bool;
}

let connect fd =
  let read_buffer_size = 32768 in
  let read_buffer = Cstruct.create read_buffer_size in
  let closed = false in
  { fd; read_buffer_size; read_buffer; closed }

let close t =
  match t.closed with
  | false ->
    t.closed <- true;
    Lwt_unix.close t.fd
  | true ->
    Lwt.return ()

let read flow =
  if flow.closed then return `Eof
  else begin
    if Cstruct.len flow.read_buffer = 0
    then flow.read_buffer <- Cstruct.create flow.read_buffer_size;
    Lwt_cstruct.read flow.fd flow.read_buffer
    >>= function
    | 0 ->
      return `Eof
    | n ->
      let result = Cstruct.sub flow.read_buffer 0 n in
      flow.read_buffer <- Cstruct.shift flow.read_buffer n;
      return (`Ok result)
  end

let rec read_into flow buf =
  if flow.closed then return `Eof
  else if Cstruct.len buf = 0
  then return (`Ok ())
  else begin
    Lwt_cstruct.read flow.fd buf
    >>= function
    | 0 ->
      return `Eof
    | n ->
      let remaining = Cstruct.shift buf n in
      read_into flow remaining
  end

let write flow buf =
  if flow.closed then return `Eof
  else
    Lwt.catch
      (fun () ->
        Lwt_cstruct.(complete (write flow.fd) buf)
        >>= fun () ->
        return (`Ok ())
      ) (function
        | Unix.Unix_error(Unix.EPIPE, _, _) -> return `Eof
        | e -> fail e)

let writev flow bufs =
  let rec loop = function
    | [] -> return (`Ok ())
    | x :: xs ->
      if flow.closed then return `Eof
      else
        Lwt.catch
          (fun () ->
            Lwt_cstruct.(complete (write flow.fd) x)
            >>= fun () ->
            loop xs
          ) (function
            | Unix.Unix_error(Unix.EPIPE, _, _) -> return `Eof
            | e -> fail e) in
  loop bufs
