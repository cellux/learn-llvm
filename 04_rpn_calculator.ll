; simple RPN calculator
;
; send the input on stdin
;
; rules:
;
;   numbers are pushed to the stack
;
;   `+', `-', `*' and `/' pop two elements from stack, apply the
;   operation and push the result
;
;   `.' pops a number and prints it
;
; example:
;
;   12 9 + 3 / . => 7
;

;;; imports

; FILE* stdin;
%FILE.T = type i8*
@stdin = external global %FILE.T

; int getc(FILE *stream);
declare i32 @getc(i8*)

; int isspace(int c);
declare i32 @isspace(i32)

; int printf(const char *format, ...);
declare i32 @printf(i8*, ...)

; double strtod(const char *nptr, char **endptr);
declare double @strtod(i8*, i8**)

; extern int *__errno_location (void) __THROW __attribute__ ((__const__));
declare i32* @__errno_location()

; void exit (int STATUS)
declare void @exit(i32) noreturn

;;; strings

@invalid_input.S = internal constant [21 x i8] c"Invalid input: [%s]\0A\00"
@result.S = internal constant [4 x i8] c"%g\0A\00"
@stack_overflow.S = internal constant [17 x i8] c"Stack overflow!\0A\00"
@stack_underflow.S = internal constant [18 x i8] c"Stack underflow!\0A\00"

;;; stack ADT

; stack of doubles, max capacity = 64 (hard-coded as there is no way to #define)

%stack.T = type { i32, [64 x double] } ; { index, elements }

define void @stack_push(%stack.T* %stack, double %val) {
  %index.P = getelementptr %stack.T* %stack, i32 0, i32 0
  %index.V = load i32* %index.P
  %cond.overflow = icmp uge i32 %index.V, 64
  br i1 %cond.overflow, label %OVERFLOW, label %OK
OK:
  %element.P = getelementptr %stack.T* %stack, i32 0, i32 1, i32 %index.V
  store double %val, double* %element.P
  %index.I = add i32 %index.V, 1
  store i32 %index.I, i32* %index.P
  ret void
OVERFLOW:
  %stack_overflow.S = getelementptr [17 x i8]* @stack_overflow.S, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %stack_overflow.S)
  call void @exit(i32 1) noreturn
  ret void
}

define double @stack_pop(%stack.T* %stack) {
  %index.P = getelementptr %stack.T* %stack, i32 0, i32 0
  %index.V = load i32* %index.P
  %cond.underflow = icmp eq i32 %index.V, 0
  br i1 %cond.underflow, label %UNDERFLOW, label %OK
OK:
  %index.I = sub i32 %index.V, 1
  store i32 %index.I, i32* %index.P
  %element.P = getelementptr %stack.T* %stack, i32 0, i32 1, i32 %index.I
  %val = load double* %element.P
  ret double %val
UNDERFLOW:
  %stack_underflow.S = getelementptr [18 x i8]* @stack_underflow.S, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %stack_underflow.S)
  call void @exit(i32 1) noreturn
  ret double undef
}

;;; main

define i32 @get_errno() {
  %errno.P = call i32* @__errno_location()
  %errno.V = load i32* %errno.P
  ret i32 %errno.V
}

define void @set_errno(i32 %val) {
  %errno.P = call i32* @__errno_location()
  store i32 %val, i32* %errno.P
  ret void
}

define i32 @read_char() {
  %stdin = load %FILE.T* @stdin
  %c = call i32 @getc(%FILE.T %stdin)
  ret i32 %c
}

define i32 @read_word(i8* %buf, i32 %bufsize) {
  %index.A = alloca i32
  store i32 0, i32* %index.A
  br label %LOOP
LOOP:
  %index.V = load i32* %index.A
  %cond.loop = icmp uge i32 %index.V, %bufsize
  br i1 %cond.loop, label %END, label %READ
READ:
  %c = call i32 @read_char()
  %cond.eof = icmp slt i32 %c, 0
  br i1 %cond.eof, label %END, label %NOT_EOF
NOT_EOF:
  %isspace = call i32 @isspace(i32 %c)
  %cond.isspace = icmp ne i32 %isspace, 0
  %cond.bufempty = icmp eq i32 %index.V, 0
  br i1 %cond.bufempty, label %SKIP_SPACES, label %APPEND_CHAR
SKIP_SPACES:
  br i1 %cond.isspace, label %READ, label %NOT_SPACE
APPEND_CHAR:
  br i1 %cond.isspace, label %END, label %NOT_SPACE
NOT_SPACE:
  %buf.P = getelementptr i8* %buf, i32 %index.V
  %c.i8 = trunc i32 %c to i8
  store i8 %c.i8, i8* %buf.P
  %index.I = add i32 %index.V, 1
  store i32 %index.I, i32* %index.A
  br label %LOOP
END:
  ret i32 %index.V
}

define i1 @is_number(i8* %buf, i32 %len) {
  %result.A = alloca i1
  store i1 true, i1* %result.A
  %index.A = alloca i32
  store i32 0, i32* %index.A
  br label %LOOP
LOOP:
  %index.V = load i32* %index.A
  %cond.loop = icmp eq i32 %index.V, %len
  br i1 %cond.loop, label %END, label %CHECK_DIGIT
CHECK_DIGIT:
  %c.P = getelementptr i8* %buf, i32 %index.V
  %c = load i8* %c.P
  %cond.ge.0 = icmp uge i8 %c, 48
  %cond.le.9 = icmp ule i8 %c, 57
  %cond.digit = and i1 %cond.ge.0, %cond.le.9
  br i1 %cond.digit, label %IS_DIGIT, label %NAN
IS_DIGIT:
  %index.I = add i32 %index.V, 1
  store i32 %index.I, i32* %index.A
  br label %LOOP
NAN:
  store i1 false, i1* %result.A
  br label %END
END:
  %result.V = load i1* %result.A
  ret i1 %result.V
}

define { i1, double } @parse_number(i8* %s, i32 %len) {
  %endptr.P = alloca i8*
  call void @set_errno(i32 0)
  %rv = call double @strtod(i8* %s, i8** %endptr.P)

  ; %cond.errno <- errno is zero
  %errno = call i32 @get_errno()
  %cond.errno = icmp eq i32 %errno, 0
  ; %cond.endptr <- endptr is at end of string
  %s.end = getelementptr i8* %s, i32 %len
  %endptr.V = load i8** %endptr.P
  %cond.endptr = icmp eq i8* %endptr.V, %s.end

  %status = and i1 %cond.errno, %cond.endptr
  %result.0 = insertvalue { i1, double } undef, i1 %status, 0
  %result.1 = insertvalue { i1, double } %result.0, double %rv, 1
  ret { i1, double } %result.1
}

define i1 @is_op(i8* %buf, i32 %len) {
  %result.A = alloca i1
  store i1 false, i1* %result.A
  %cond.len = icmp eq i32 %len, 1
  br i1 %cond.len, label %CHECK, label %END
CHECK:
  %c = load i8* %buf
  switch i8 %c, label %END [ i8 43, label %IS_OP
                             i8 45, label %IS_OP
                             i8 42, label %IS_OP
                             i8 47, label %IS_OP ]
IS_OP:
  store i1 true, i1* %result.A
  br label %END
END:
  %result.V = load i1* %result.A
  ret i1 %result.V
}

define i8 @parse_op(i8* %buf, i32 %len) {
  %op = load i8* %buf
  ret i8 %op
}

define i1 @is_dot(i8* %buf, i32 %len) {
  %result.A = alloca i1
  store i1 false, i1* %result.A
  %cond.len = icmp eq i32 %len, 1
  br i1 %cond.len, label %CHECK, label %END
CHECK:
  %c = load i8* %buf
  %cond.dot = icmp eq i8 %c, 46
  br i1 %cond.dot, label %IS_DOT, label %END
IS_DOT:
  store i1 true, i1* %result.A
  br label %END
END:
  %result.V = load i1* %result.A
  ret i1 %result.V
}

define i32 @main(i32 %argc, i8** %argv) {
  %stack.A = alloca %stack.T
  %stack.index.P = getelementptr %stack.T* %stack.A, i32 0, i32 0
  store i32 0, i32* %stack.index.P
  %buf.A = alloca i8, i32 256
  br label %LOOP
LOOP:
  %len = call i32 @read_word(i8* %buf.A, i32 255)
  %cond.eof = icmp eq i32 %len, 0
  br i1 %cond.eof, label %END, label %WORD_OK
WORD_OK:
  ; put an ASCII \0 to the end
  %end.P = getelementptr i8* %buf.A, i32 %len
  store i8 0, i8* %end.P
  br label %CHECK_NUMBER
CHECK_NUMBER:
  %cond.number = call i1 @is_number(i8* %buf.A, i32 %len)
  br i1 %cond.number, label %DO_NUMBER, label %CHECK_OP
CHECK_OP:
  %cond.op = call i1 @is_op(i8* %buf.A, i32 %len)
  br i1 %cond.op, label %DO_OP, label %CHECK_DOT
CHECK_DOT:
  %cond.dot = call i1 @is_dot(i8* %buf.A, i32 %len)
  br i1 %cond.dot, label %DO_DOT, label %ERROR
ERROR:
  %invalid_input.S = getelementptr [21 x i8]* @invalid_input.S, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %invalid_input.S, i8* %buf.A)
  ; perhaps we should bail out here
  br label %LOOP

DO_NUMBER:
  %parse_result = call { i1, double } @parse_number(i8* %buf.A, i32 %len)
  %parse_result.status = extractvalue { i1, double } %parse_result, 0
  br i1 %parse_result.status, label %NUMBER_PARSED, label %ERROR
NUMBER_PARSED:
  %parse_result.num = extractvalue { i1, double } %parse_result, 1
  call void @stack_push(%stack.T* %stack.A, double %parse_result.num)
  br label %LOOP

DO_OP:
  %op = call i8 @parse_op(i8* %buf.A, i32 %len)
  ; rhs is on top, lhs one below
  %op.rhs = call double @stack_pop(%stack.T* %stack.A)
  %op.lhs = call double @stack_pop(%stack.T* %stack.A)
  %op.res.A = alloca double
  switch i8 %op, label %ERROR [ i8 43, label %DO_ADD
                                i8 45, label %DO_SUB
                                i8 42, label %DO_MUL
                                i8 47, label %DO_DIV ]
DO_ADD:
  %add.res = fadd double %op.lhs, %op.rhs
  store double %add.res, double* %op.res.A
  br label %OP_DONE
DO_SUB:
  %sub.res = fsub double %op.lhs, %op.rhs
  store double %sub.res, double* %op.res.A
  br label %OP_DONE
DO_MUL:
  %mul.res = fmul double %op.lhs, %op.rhs
  store double %mul.res, double* %op.res.A
  br label %OP_DONE
DO_DIV:
  %div.res = fdiv double %op.lhs, %op.rhs
  store double %div.res, double* %op.res.A
  br label %OP_DONE
OP_DONE:
  %op.res.V = load double* %op.res.A
  call void @stack_push(%stack.T* %stack.A, double %op.res.V)
  br label %LOOP

DO_DOT:
  %stack.top = call double @stack_pop(%stack.T* %stack.A)
  %result.S = getelementptr [4 x i8]* @result.S, i32 0, i32 0
  call i32 (i8*,...)* @printf(i8* %result.S, double %stack.top)
  br label %LOOP

END:
  ret i32 0
}
