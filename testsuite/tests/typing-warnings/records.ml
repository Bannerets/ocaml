(* TEST
   flags = " -w A -strict-sequence "
   * expect
*)

(* Use type information *)
module M1 = struct
  type t = {x: int; y: int}
  type u = {x: bool; y: bool}
end;;
[%%expect{|
module M1 :
  sig type t = { x : int; y : int; } type u = { x : bool; y : bool; } end
|}]

module OK = struct
  open M1
  let f1 (r:t) = r.x (* ok *)
  let f2 r = ignore (r:t); r.x (* non principal *)

  let f3 (r: t) =
    match r with {x; y} -> y + y (* ok *)
end;;
[%%expect{|
Line 3, characters 19-20:
    let f1 (r:t) = r.x (* ok *)
                     ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 4, characters 29-30:
    let f2 r = ignore (r:t); r.x (* non principal *)
                               ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 7, characters 18-19:
      match r with {x; y} -> y + y (* ok *)
                    ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 7, characters 21-22:
      match r with {x; y} -> y + y (* ok *)
                       ^
Warning 42: this use of y relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 7, characters 18-19:
      match r with {x; y} -> y + y (* ok *)
                    ^
Warning 27: unused variable x.
module OK :
  sig val f1 : M1.t -> int val f2 : M1.t -> int val f3 : M1.t -> int end
|}, Principal{|
Line 3, characters 19-20:
    let f1 (r:t) = r.x (* ok *)
                     ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 4, characters 29-30:
    let f2 r = ignore (r:t); r.x (* non principal *)
                               ^
Warning 18: this type-based field disambiguation is not principal.
Line 4, characters 29-30:
    let f2 r = ignore (r:t); r.x (* non principal *)
                               ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 7, characters 18-19:
      match r with {x; y} -> y + y (* ok *)
                    ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 7, characters 21-22:
      match r with {x; y} -> y + y (* ok *)
                       ^
Warning 42: this use of y relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 7, characters 18-19:
      match r with {x; y} -> y + y (* ok *)
                    ^
Warning 27: unused variable x.
module OK :
  sig val f1 : M1.t -> int val f2 : M1.t -> int val f3 : M1.t -> int end
|}]

module F1 = struct
  open M1
  let f r = match r with {x; y} -> y + y
end;; (* fails *)
[%%expect{|
Line 3, characters 25-31:
    let f r = match r with {x; y} -> y + y
                           ^^^^^^
Warning 41: these field labels belong to several types: M1.u M1.t
The first one was selected. Please disambiguate if this is wrong.
Line 3, characters 35-36:
    let f r = match r with {x; y} -> y + y
                                     ^
Error: This expression has type bool but an expression was expected of type
         int
|}]

module F2 = struct
  open M1
  let f r =
    ignore (r: t);
    match r with
       {x; y} -> y + y
end;; (* fails for -principal *)
[%%expect{|
Line 6, characters 8-9:
         {x; y} -> y + y
          ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 6, characters 11-12:
         {x; y} -> y + y
             ^
Warning 42: this use of y relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 6, characters 8-9:
         {x; y} -> y + y
          ^
Warning 27: unused variable x.
module F2 : sig val f : M1.t -> int end
|}, Principal{|
Line 6, characters 7-13:
         {x; y} -> y + y
         ^^^^^^
Warning 41: these field labels belong to several types: M1.u M1.t
The first one was selected. Please disambiguate if this is wrong.
Line 6, characters 7-13:
         {x; y} -> y + y
         ^^^^^^
Error: This pattern matches values of type M1.u
       but a pattern was expected which matches values of type M1.t
|}]

(* Use type information with modules*)
module M = struct
  type t = {x:int}
  type u = {x:bool}
end;;
[%%expect{|
module M : sig type t = { x : int; } type u = { x : bool; } end
|}]
let f (r:M.t) = r.M.x;; (* ok *)
[%%expect{|
Line 1, characters 18-21:
  let f (r:M.t) = r.M.x;; (* ok *)
                    ^^^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
val f : M.t -> int = <fun>
|}]
let f (r:M.t) = r.x;; (* warning *)
[%%expect{|
Line 1, characters 18-19:
  let f (r:M.t) = r.x;; (* warning *)
                    ^
Warning 40: x was selected from type M.t.
It is not visible in the current scope, and will not
be selected if the type becomes unknown.
Line 1, characters 18-19:
  let f (r:M.t) = r.x;; (* warning *)
                    ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
val f : M.t -> int = <fun>
|}]
let f ({x}:M.t) = x;; (* warning *)
[%%expect{|
Line 1, characters 8-9:
  let f ({x}:M.t) = x;; (* warning *)
          ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 1, characters 7-10:
  let f ({x}:M.t) = x;; (* warning *)
         ^^^
Warning 40: this record of type M.t contains fields that are
not visible in the current scope: x.
They will not be selected if the type becomes unknown.
val f : M.t -> int = <fun>
|}]

module M = struct
  type t = {x: int; y: int}
end;;
[%%expect{|
module M : sig type t = { x : int; y : int; } end
|}]
module N = struct
  type u = {x: bool; y: bool}
end;;
[%%expect{|
module N : sig type u = { x : bool; y : bool; } end
|}]
module OK = struct
  open M
  open N
  let f (r:M.t) = r.x
end;;
[%%expect{|
Line 4, characters 20-21:
    let f (r:M.t) = r.x
                      ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 3, characters 2-8:
    open N
    ^^^^^^
Warning 33: unused open N.
module OK : sig val f : M.t -> int end
|}]

module M = struct
  type t = {x:int}
  module N = struct type s = t = {x:int} end
  type u = {x:bool}
end;;
[%%expect{|
module M :
  sig
    type t = { x : int; }
    module N : sig type s = t = { x : int; } end
    type u = { x : bool; }
  end
|}]
module OK = struct
  open M.N
  let f (r:M.t) = r.x
end;;
[%%expect{|
module OK : sig val f : M.t -> int end
|}]

(* Use field information *)
module M = struct
  type u = {x:bool;y:int;z:char}
  type t = {x:int;y:bool}
end;;
[%%expect{|
module M :
  sig
    type u = { x : bool; y : int; z : char; }
    type t = { x : int; y : bool; }
  end
|}]
module OK = struct
  open M
  let f {x;z} = x,z
end;; (* ok *)
[%%expect{|
Line 3, characters 9-10:
    let f {x;z} = x,z
           ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 3, characters 8-13:
    let f {x;z} = x,z
          ^^^^^
Warning 9: the following labels are not bound in this record pattern:
y
Either bind these labels explicitly or add '; _' to the pattern.
module OK : sig val f : M.u -> bool * char end
|}]
module F3 = struct
  open M
  let r = {x=true;z='z'}
end;; (* fail for missing label *)
[%%expect{|
Line 3, characters 10-24:
    let r = {x=true;z='z'}
            ^^^^^^^^^^^^^^
Error: Some record fields are undefined: y
|}]

module OK = struct
  type u = {x:int;y:bool}
  type t = {x:bool;y:int;z:char}
  let r = {x=3; y=true}
end;; (* ok *)
[%%expect{|
Line 4, characters 11-12:
    let r = {x=3; y=true}
             ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 4, characters 16-17:
    let r = {x=3; y=true}
                  ^
Warning 42: this use of y relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
module OK :
  sig
    type u = { x : int; y : bool; }
    type t = { x : bool; y : int; z : char; }
    val r : u
  end
|}]

(* Corner cases *)

module F4 = struct
  type foo = {x:int; y:int}
  type bar = {x:int}
  let b : bar = {x=3; y=4}
end;; (* fail but don't warn *)
[%%expect{|
Line 4, characters 22-23:
    let b : bar = {x=3; y=4}
                        ^
Error: This record expression is expected to have type bar
       The field y does not belong to type bar
|}]

module M = struct type foo = {x:int;y:int} end;;
[%%expect{|
module M : sig type foo = { x : int; y : int; } end
|}]
module N = struct type bar = {x:int;y:int} end;;
[%%expect{|
module N : sig type bar = { x : int; y : int; } end
|}]
let r = { M.x = 3; N.y = 4; };; (* error: different definitions *)
[%%expect{|
Line 1, characters 19-22:
  let r = { M.x = 3; N.y = 4; };; (* error: different definitions *)
                     ^^^
Error: The record field N.y belongs to the type N.bar
       but is mixed here with fields of type M.foo
|}]

module MN = struct include M include N end
module NM = struct include N include M end;;
[%%expect{|
module MN :
  sig
    type foo = M.foo = { x : int; y : int; }
    type bar = N.bar = { x : int; y : int; }
  end
module NM :
  sig
    type bar = N.bar = { x : int; y : int; }
    type foo = M.foo = { x : int; y : int; }
  end
|}]
let r = {MN.x = 3; NM.y = 4};; (* error: type would change with order *)
[%%expect{|
Line 1, characters 8-28:
  let r = {MN.x = 3; NM.y = 4};; (* error: type would change with order *)
          ^^^^^^^^^^^^^^^^^^^^
Warning 41: x belongs to several types: MN.bar MN.foo
The first one was selected. Please disambiguate if this is wrong.
Line 1, characters 8-28:
  let r = {MN.x = 3; NM.y = 4};; (* error: type would change with order *)
          ^^^^^^^^^^^^^^^^^^^^
Warning 41: y belongs to several types: NM.foo NM.bar
The first one was selected. Please disambiguate if this is wrong.
Line 1, characters 19-23:
  let r = {MN.x = 3; NM.y = 4};; (* error: type would change with order *)
                     ^^^^
Error: The record field NM.y belongs to the type NM.foo = M.foo
       but is mixed here with fields of type MN.bar = N.bar
|}]

(* Lpw25 *)

module M = struct
  type foo = { x: int; y: int }
  type bar = { x:int; y: int; z: int}
end;;
[%%expect{|
module M :
  sig
    type foo = { x : int; y : int; }
    type bar = { x : int; y : int; z : int; }
  end
|}]
module F5 = struct
  open M
  let f r = ignore (r: foo); {r with x = 2; z = 3}
end;;
[%%expect{|
Line 3, characters 37-38:
    let f r = ignore (r: foo); {r with x = 2; z = 3}
                                       ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 3, characters 44-45:
    let f r = ignore (r: foo); {r with x = 2; z = 3}
                                              ^
Error: This record expression is expected to have type M.foo
       The field z does not belong to type M.foo
|}]
module M = struct
  include M
  type other = { a: int; b: int }
end;;
[%%expect{|
module M :
  sig
    type foo = M.foo = { x : int; y : int; }
    type bar = M.bar = { x : int; y : int; z : int; }
    type other = { a : int; b : int; }
  end
|}]
module F6 = struct
  open M
  let f r = ignore (r: foo); { r with x = 3; a = 4 }
end;;
[%%expect{|
Line 3, characters 38-39:
    let f r = ignore (r: foo); { r with x = 3; a = 4 }
                                        ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 3, characters 45-46:
    let f r = ignore (r: foo); { r with x = 3; a = 4 }
                                               ^
Error: This record expression is expected to have type M.foo
       The field a does not belong to type M.foo
|}]
module F7 = struct
  open M
  let r = {x=1; y=2}
  let r: other = {x=1; y=2}
end;;
[%%expect{|
Line 3, characters 11-12:
    let r = {x=1; y=2}
             ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 3, characters 16-17:
    let r = {x=1; y=2}
                  ^
Warning 42: this use of y relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 4, characters 18-19:
    let r: other = {x=1; y=2}
                    ^
Error: This record expression is expected to have type M.other
       The field x does not belong to type M.other
|}]

module A = struct type t = {x: int} end
module B = struct type t = {x: int} end;;
[%%expect{|
module A : sig type t = { x : int; } end
module B : sig type t = { x : int; } end
|}]
let f (r : B.t) = r.A.x;; (* fail *)
[%%expect{|
Line 1, characters 20-23:
  let f (r : B.t) = r.A.x;; (* fail *)
                      ^^^
Error: The field A.x belongs to the record type A.t
       but a field was expected belonging to the record type B.t
|}]

(* Spellchecking *)

module F8 = struct
  type t = {x:int; yyy:int}
  let a : t = {x=1;yyz=2}
end;;
[%%expect{|
Line 3, characters 19-22:
    let a : t = {x=1;yyz=2}
                     ^^^
Error: This record expression is expected to have type t
       The field yyz does not belong to type t
Hint: Did you mean yyy?
|}]

(* PR#6004 *)

type t = A
type s = A

class f (_ : t) = object end;;
[%%expect{|
type t = A
type s = A
class f : t -> object  end
|}]
class g = f A;; (* ok *)

class f (_ : 'a) (_ : 'a) = object end;;
[%%expect{|
Line 1, characters 12-13:
  class g = f A;; (* ok *)
              ^
Warning 42: this use of A relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
class g : f
class f : 'a -> 'a -> object  end
|}]
class g = f (A : t) A;; (* warn with -principal *)
[%%expect{|
Line 1, characters 13-14:
  class g = f (A : t) A;; (* warn with -principal *)
               ^
Warning 42: this use of A relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 1, characters 20-21:
  class g = f (A : t) A;; (* warn with -principal *)
                      ^
Warning 42: this use of A relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
class g : f
|}, Principal{|
Line 1, characters 13-14:
  class g = f (A : t) A;; (* warn with -principal *)
               ^
Warning 42: this use of A relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 1, characters 20-21:
  class g = f (A : t) A;; (* warn with -principal *)
                      ^
Warning 18: this type-based constructor disambiguation is not principal.
Line 1, characters 20-21:
  class g = f (A : t) A;; (* warn with -principal *)
                      ^
Warning 42: this use of A relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
class g : f
|}]


(* PR#5980 *)

module Shadow1 = struct
  type t = {x: int}
  module M = struct
    type s = {x: string}
  end
  open M  (* this open is unused, it isn't reported as shadowing 'x' *)
  let y : t = {x = 0}
end;;
[%%expect{|
Line 7, characters 15-16:
    let y : t = {x = 0}
                 ^
Warning 42: this use of x relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
Line 6, characters 2-8:
    open M  (* this open is unused, it isn't reported as shadowing 'x' *)
    ^^^^^^
Warning 33: unused open M.
module Shadow1 :
  sig
    type t = { x : int; }
    module M : sig type s = { x : string; } end
    val y : t
  end
|}]
module Shadow2 = struct
  type t = {x: int}
  module M = struct
    type s = {x: string}
  end
  open M  (* this open shadows label 'x' *)
  let y = {x = ""}
end;;
[%%expect{|
Line 6, characters 2-8:
    open M  (* this open shadows label 'x' *)
    ^^^^^^
Warning 45: this open statement shadows the label x (which is later used)
Line 7, characters 10-18:
    let y = {x = ""}
            ^^^^^^^^
Warning 41: these field labels belong to several types: M.s t
The first one was selected. Please disambiguate if this is wrong.
module Shadow2 :
  sig
    type t = { x : int; }
    module M : sig type s = { x : string; } end
    val y : M.s
  end
|}]

(* PR#6235 *)

module P6235 = struct
  type t = { loc : string; }
  type v = { loc : string; x : int; }
  type u = [ `Key of t ]
  let f (u : u) = match u with `Key {loc} -> loc
end;;
[%%expect{|
Line 5, characters 37-40:
    let f (u : u) = match u with `Key {loc} -> loc
                                       ^^^
Warning 42: this use of loc relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
module P6235 :
  sig
    type t = { loc : string; }
    type v = { loc : string; x : int; }
    type u = [ `Key of t ]
    val f : u -> string
  end
|}]

(* Remove interaction between branches *)

module P6235' = struct
  type t = { loc : string; }
  type v = { loc : string; x : int; }
  type u = [ `Key of t ]
  let f = function
    | (_ : u) when false -> ""
    |`Key {loc} -> loc
end;;
[%%expect{|
Line 7, characters 11-14:
      |`Key {loc} -> loc
             ^^^
Warning 42: this use of loc relies on type-directed disambiguation,
it will not compile with OCaml 4.00 or earlier.
module P6235' :
  sig
    type t = { loc : string; }
    type v = { loc : string; x : int; }
    type u = [ `Key of t ]
    val f : u -> string
  end
|}, Principal{|
Line 7, characters 10-15:
      |`Key {loc} -> loc
            ^^^^^
Warning 41: these field labels belong to several types: v t
The first one was selected. Please disambiguate if this is wrong.
Line 7, characters 10-15:
      |`Key {loc} -> loc
            ^^^^^
Warning 9: the following labels are not bound in this record pattern:
x
Either bind these labels explicitly or add '; _' to the pattern.
Line 7, characters 5-15:
      |`Key {loc} -> loc
       ^^^^^^^^^^
Error: This pattern matches values of type [? `Key of v ]
       but a pattern was expected which matches values of type u
       Types for tag `Key are incompatible
|}]
