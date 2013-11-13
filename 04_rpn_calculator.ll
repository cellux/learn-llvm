; simple RPN calculator
;
; send the input on stdin
;
; 12 9 + 3 /
; => 7

; WORK IN PROGRESS

; stdin
%FILE.t = type i8*
@stdin = external global %FILE.t

; int getc(FILE *stream);
declare i32 @getc(i8*)

; int isspace(int c);
declare i32 @isspace(i32)

; int printf(const char *format, ...);
declare i32 @printf(i8*, ...)

define i32 @read_char() {
  %stdin = load %FILE.t* @stdin
  %c = call i32 @getc(%FILE.t %stdin)
  ret i32 %c
}

define i32 @read_word(i8* %buf, i32 %bufsize) {
  %index.var = alloca i32
  store i32 0, i32* %index.var
  br label %LOOP
LOOP:
  %index.val = load i32* %index.var
  %index.cond = icmp uge i32 %index.val, %bufsize
  br i1 %index.cond, label %END, label %READ
READ:
  %c = call i32 @read_char()
  %eof.cond = icmp slt i32 %c, 0
  br i1 %eof.cond, label %END, label %NOT.EOF
NOT.EOF:
  %is.space.rv = call i32 @isspace(i32 %c)
  %is.space.cond = icmp ne i32 %is.space.rv, 0
  %is.buf.empty = icmp eq i32 %index.val, 0
  br i1 %is.buf.empty, label %SKIP.SPACES, label %APPEND.CHAR
SKIP.SPACES:
  br i1 %is.space.cond, label %READ, label %NOT.SPACE
APPEND.CHAR:
  br i1 %is.space.cond, label %END, label %NOT.SPACE
NOT.SPACE:
  %buf.ptr = getelementptr i8* %buf, i32 %index.val
  %c.i8 = trunc i32 %c to i8
  store i8 %c.i8, i8* %buf.ptr
  %index.val.inc = add i32 %index.val, 1
  store i32 %index.val.inc, i32* %index.var
  br label %LOOP
END:
  ret i32 %index.val
}

@got_word.s = internal constant [14 x i8] c"Got word: %s\0A\00"

define i32 @main(i32 %argc, i8** %argv) {
  %buf = alloca i8, i8 256
  br label %LOOP
LOOP:
  %len = call i32 @read_word(i8* %buf, i32 256)
  %is.eof = icmp eq i32 %len, 0
  br i1 %is.eof, label %END, label %PRINT
PRINT:
  %end.ptr = getelementptr i8* %buf, i32 %len
  store i8 0, i8* %end.ptr
  %got_word.s = getelementptr [14 x i8]* @got_word.s, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %got_word.s, i8* %buf)
  br label %LOOP
END:
  ret i32 0
}
