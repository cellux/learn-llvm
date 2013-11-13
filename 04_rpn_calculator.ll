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

@invalid_input.s = internal constant [21 x i8] c"Invalid input: [%s]\0A\00"

@result.s = internal constant [6 x i8] c"%lld\0A\00"

%stack.t = type { i32, [64 x i64] } ; index, data

define i1 @is_number(i8* %buf, i32 %len) {
  %result.var = alloca i1
  store i1 true, i1* %result.var
  %index.var = alloca i32
  store i32 0, i32* %index.var
LOOP:
  %index.val = load i32* %index.var
  %done = icmp eq i32 %index.val, %len
  br i1 %done, label %END, label %CHECK_DIGIT
CHECK_DIGIT:
  %c.ptr = getelementptr i8* %buf, i32 %index.val
  %c = load i8* %c.ptr
  %is.ge.0 = icmp uge %c, 48
  %is.le.9 = icmp ule %c, 57
  %is.digit = and i1 %is.ge.0, %is.le.9
  br i1 %is.digit, label %IS_DIGIT, label %NAN
IS_DIGIT:
  %index.val.inc = add i32 %index.val, 1
  store i32 %index.val.inc, i32* %index.var
  br label %LOOP
NAN:
  store i1 false, i1* %result.var
END:
  %result.val = load i1* %result.var
  ret %result.val
}

define i1 @is_op(i8* %buf, i32 %len) {
  %result.var = alloca i1
  store i1 false, i1* %result.var
  %len.ok = icmp eq i32 %len, 1
  br i1 %len.ok, label %CHECK, label %END
CHECK:
  %c = load i8* %buf
  switch i8 %c, label %END, [ i8 43, %IS_OP
                              i8 45, %IS_OP
                              i8 42, %IS_OP
                              i8 47, %IS_OP ]
IS_OP:
  store i1 true, i1* %result.var
END:
  %result.val = load i1* %result.var
  ret %result.val
}

define i1 @is_dot(i8* %buf, i32 %len) {
  %result.var = alloca i1
  store i1 false, i1* %result.var
  %len.ok = icmp eq i32 %len, 1
  br i1 %len.ok, label %CHECK, label %END
CHECK:
  %c = load i8* %buf
  %is.dot = icmp eq i8 %c, 46
  br i1 %is.dot, label %IS_DOT, label %END
IS_DOT:
  store i1 true, i1* %result.var
END:
  %result.val = load i1* %result.var
  ret %result.val
}

define i64 @parse_number(i8* %buf, i32 len) {
  ; TODO
}

define i32 @parse_op(i8* %buf, i32 len) {
  ; TODO
}

define void @stack_push(%stack.t* %stack, i64 %val) {
  ; TODO
}

define i64 @stack_pop(%stack.t* %stack) {
  ; TODO
}

define i32 @main(i32 %argc, i8** %argv) {
  %stack = alloca %stack.t
  %stack.index = getelementptr %stack, 0, 0
  store i32 0, i32* %stack.index
  %buf = alloca i8, i32 256
  br label %LOOP
LOOP:
  %len = call i32 @read_word(i8* %buf, i32 255)
  %is.eof = icmp eq i32 %len, 0
  br i1 %is.eof, label %END, label %ZERO_TERMINATE
ZERO_TERMINATE:
  %end.ptr = getelementptr i8* %buf, i32 %len
  store i8 0, i8* %end.ptr
  br label %CHECK_NUMBER
CHECK_NUMBER:
  i1 %is.number = call i1 @is_number(i8* %buf, i32 %len)
  b1 i1 is.number, label %PROCESS_NUMBER, label %CHECK_OP
CHECK_OP:
  i1 %is.op = call i1 @is_op(i8* %buf, i32 %len)
  b1 i1 is.op, label %PROCESS_OP, label %CHECK_DOT
CHECK_DOT:
  i1 %is.dot = call i1 @is_dot(i8* %buf, i32 %len)
  b1 i1 is.dot, label %PROCESS_DOT, label %ERROR
ERROR:
  %invalid_input.s = getelementptr [21 x i8]* @invalid_input.s, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %invalid_input.s, i8* %buf)
  br label %LOOP
PROCESS_NUMBER:
  %num = call i64 @parse_number(i8* %buf, i32 len)
  call void @stack_push(%stack.t* %stack, i64 %num)
  br label %LOOP
PROCESS_OP:
  %op.id = call i32 @parse_op(i8* %buf, i32 len)
  switch i32 %op.id, label %ERROR, [ i32 43, %PROCESS_ADD
                                     i32 45, %PROCESS_SUB
                                     i32 42, %PROCESS_MUL
                                     i32 47, %PROCESS_DIV ]
PROCESS_ADD:
  %add.arg1 = call i64 @stack_pop(%stack.t* %stack)
  %add.arg2 = call i64 @stack_pop(%stack.t* %stack)
  %add.res = add i64 %add.arg1, %add.arg2
  call void @stack_push(%stack.t* %stack, i64 %add.res)
  br label %LOOP
PROCESS_SUB:
  %sub.arg1 = call i64 @stack_pop(%stack.t* %stack)
  %sub.arg2 = call i64 @stack_pop(%stack.t* %stack)
  %sub.res = sub i64 %sub.arg1, %sub.arg2
  call void @stack_push(%stack.t* %stack, i64 %sub.res)
  br label %LOOP
PROCESS_MUL:
  %mul.arg1 = call i64 @stack_pop(%stack.t* %stack)
  %mul.arg2 = call i64 @stack_pop(%stack.t* %stack)
  %mul.res = mul i64 %mul.arg1, %mul.arg2
  call void @stack_push(%stack.t* %stack, i64 %mul.res)
  br label %LOOP
PROCESS_DIV:
  %div.arg1 = call i64 @stack_pop(%stack.t* %stack)
  %div.arg2 = call i64 @stack_pop(%stack.t* %stack)
  %div.res = div i64 %div.arg1, %div.arg2
  call void @stack_push(%stack.t* %stack, i64 %div.res)
  br label %LOOP
PROCESS_DOT:
  %stack.top = call i64 @stack_pop(%stack.t* %stack)
  %result.s = getelementptr [6 x i8]* @result.s, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %result.s, i64 %stack.top)
  br label %LOOP
END:
  ret i32 0
}
