(*
 * Copyright (C) 2015 David Sheets <david.sheets@unikernel.com>
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

module Make(Log: Protocol_9p.S.LOG) : sig
  include Protocol_9p.Client.S

  val connect:
    string -> string -> ?msize:int32 -> ?username:string -> ?aname:string ->
    unit -> t Protocol_9p.Error.t Lwt.t
  (** [connect proto address ?msize ?username ?aname ()] creates a 9P connection
      over [proto] to [address] with an optional maximum message size [?msize]
      and optional [?username] and authentication [?aname]. Allowed combinations
      of [proto] and [address] are:
      - unix /path/to/file
      - tcp ip:port
  *)
end
