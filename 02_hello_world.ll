; hello world

@hello.S = internal constant [14 x i8] c"Hello, world!\00"

declare i32 @puts(i8*)

define i32 @main(i32 %argc, i8** %argv) {
  %hello.S = getelementptr [14 x i8]* @hello.S, i32 0, i32 0
  call i32 @puts(i8* %hello.S)
  ret i32 0
}

