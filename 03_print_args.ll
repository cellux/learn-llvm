; print program arguments to stdout

@argc.S = internal constant [9 x i8] c"argc=%d\0A\00"
@argv.S = internal constant [13 x i8] c"argv[%d]=%s\0A\00"

declare i32 @printf(i8*, ...)

define i32 @main(i32 %argc, i8** %argv) {
  %argc.S = getelementptr [9 x i8]* @argc.S, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %argc.S, i32 %argc)
  %argv.S = getelementptr [13 x i8]* @argv.S, i32 0, i32 0
  %index.A = alloca i32
  store i32 0, i32* %index.A
  br label %LOOP
LOOP:
  %index.V = load i32* %index.A
  %cond.loop = icmp eq i32 %index.V, %argc
  br i1 %cond.loop, label %END, label %PRINT
PRINT:
  %arg.P = getelementptr i8** %argv, i32 %index.V
  %arg.V = load i8** %arg.P
  call i32 (i8*,...)* @printf(i8* %argv.S, i32 %index.V, i8* %arg.V)
  %index.I = add i32 %index.V, 1
  store i32 %index.I, i32* %index.A
  br label %LOOP
END:
  ret i32 0
}
