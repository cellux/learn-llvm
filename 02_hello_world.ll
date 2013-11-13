; hello world

@hellostr = internal constant [14 x i8] c"Hello, world!\00"

declare i32 @puts(i8*)

define i32 @main(i32 %argc,i8** %argv) {
  %hellostr = getelementptr [14 x i8]* @hellostr, i64 0, i64 0
  call i32 @puts(i8* %hellostr)
  ret i32 0
}
