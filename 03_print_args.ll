; print program arguments to stdout

@argc.fmt = internal constant [9 x i8] c"argc=%d\0A\00"
@argv.fmt = internal constant [13 x i8] c"argv[%d]=%s\0A\00"

declare i32 @printf(i8*, ...)

define i32 @main(i32 %argc,i8** %argv) {
  %argc.fmt = getelementptr [9 x i8]* @argc.fmt, i64 0, i64 0
  call i32 (i8*,...)* @printf(i8* %argc.fmt, i32 %argc)
  %argv.fmt = getelementptr [13 x i8]* @argv.fmt, i64 0, i64 0
  %i.ptr = alloca i32
  store i32 0, i32* %i.ptr
  br label %LOOP
LOOP:
  %i = load i32* %i.ptr
  %cond = icmp eq i32 %i, %argc
  br i1 %cond, label %END, label %PRINT
PRINT:
  %argv.i = getelementptr i8** %argv, i32 %i
  %arg = load i8** %argv.i
  call i32 (i8*,...)* @printf(i8* %argv.fmt, i32 %i, i8* %arg)
  %i.inc = add i32 %i, 1
  store i32 %i.inc, i32* %i.ptr
  br label %LOOP
END:
  ret i32 0
}
