||| Concurrency primitives, e.g. threads, mutexes, etc.
|||
||| N.B.: At the moment this is pretty fundamentally tied to the Scheme RTS.
||| Given that different back ends will have entirely different threading
||| models, it might be unavoidable, but we might want to think about possible
||| primitives that back ends should support.
module System.Concurrency

%default total


-- Thread mailboxes

%foreign "scheme:blodwen-set-thread-data"
prim__setThreadData : {a : Type} -> a -> PrimIO ()
%foreign "scheme:blodwen-get-thread-data"
prim__getThreadData : (a : Type) -> PrimIO a

||| Set the data stored in a thread's parameter to the given value.
||| Currently only supported under the scheme backends.
export
setThreadData : HasIO io => {a : Type} -> a -> io ()
setThreadData val = primIO (prim__setThreadData val)

||| Get the data stored in a thread's parameter.
||| Currently only supported under the scheme backends.
export
getThreadData : HasIO io => (a : Type) -> io a
getThreadData a = primIO (prim__getThreadData a)


-- Mutexes

export
data Mutex : Type where [external]

%foreign "scheme:blodwen-make-mutex"
prim__makeMutex : PrimIO Mutex
%foreign "scheme:blodwen-mutex-acquire"
prim__mutexAcquire : Mutex -> PrimIO ()
%foreign "scheme:blodwen-mutex-release"
prim__mutexRelease : Mutex -> PrimIO ()

||| Creates and returns a new mutex.
export
makeMutex : HasIO io => io Mutex
makeMutex = primIO prim__makeMutex

||| Acquires the mutex identified by `mutex`. The thread blocks until the mutex
||| has been acquired.
|||
||| Mutexes are recursive in Posix threads terminology, which means that the
||| calling thread can use mutex-acquire to (re)acquire a mutex it already has.
||| In this case, an equal number of mutex-release calls is necessary to release
||| the mutex.
export
mutexAcquire : HasIO io => Mutex -> io ()
mutexAcquire m = primIO (prim__mutexAcquire m)

||| Releases the mutex identified by `mutex`. Unpredictable behavior results if
||| the mutex is not owned by the calling thread.
export
mutexRelease : HasIO io => Mutex -> io ()
mutexRelease m = primIO (prim__mutexRelease m)


-- Condition variables

export
data Condition : Type where [external]

%foreign "scheme,racket:blodwen-make-cv"
         "scheme,chez:blodwen-make-condition"
prim__makeCondition : PrimIO Condition
%foreign "scheme,racket:blodwen-cv-wait"
         "scheme,chez:blodwen-condition-wait"
prim__conditionWait : Condition -> Mutex -> PrimIO ()
%foreign "scheme,chez:blodwen-condition-wait-timeout"
--         "scheme,racket:blodwen-cv-wait-timeout"
prim__conditionWaitTimeout : Condition -> Mutex -> Int -> PrimIO ()
%foreign "scheme,racket:blodwen-cv-signal"
         "scheme,chez:blodwen-condition-signal"
prim__conditionSignal : Condition -> PrimIO ()
%foreign "scheme,racket:blodwen-cv-broadcast"
         "scheme,chez:blodwen-condition-broadcast"
prim__conditionBroadcast : Condition -> PrimIO ()


||| Creates and returns a new condition variable.
export
makeCondition : HasIO io => io Condition
makeCondition = primIO prim__makeCondition

||| Waits up to the specified timeout for the condition identified by the
||| condition variable `cond`. The calling thread must have acquired the mutex
||| identified by `mutex` at the time `conditionWait` is called. The mutex is
||| released as a side effect of the call to `conditionWait`. When a thread is
||| later released from the condition variable by one of the procedures
||| described below, the mutex is reacquired and `conditionWait` returns.
export
conditionWait : HasIO io => Condition -> Mutex -> io ()
conditionWait cond mutex = primIO (prim__conditionWait cond mutex)

||| Variant of `conditionWait` with a timeout in microseconds.
||| When the timeout expires, the thread is released, `mutex` is reacquired, and
||| `conditionWaitTimeout` returns.
export
conditionWaitTimeout : HasIO io => Condition -> Mutex -> Int -> io ()
conditionWaitTimeout cond mutex timeout = primIO (prim__conditionWaitTimeout cond mutex timeout)

||| Releases one of the threads waiting for the condition identified by `cond`.
export
conditionSignal : HasIO io => Condition -> io ()
conditionSignal c = primIO (prim__conditionSignal c)

||| Releases all of the threads waiting for the condition identified by `cond`.
export
conditionBroadcast : HasIO io => Condition -> io ()
conditionBroadcast c = primIO (prim__conditionBroadcast c)


-- Semaphores

export
data Semaphore : Type where [external]

%foreign "scheme:blodwen-make-semaphore"
prim__makeSemaphore : Int -> PrimIO Semaphore
%foreign "scheme:blodwen-semaphore-post"
prim__semaphorePost : Semaphore -> PrimIO ()
%foreign "scheme:blodwen-semaphore-wait"
prim__semaphoreWait : Semaphore -> PrimIO ()


||| Creates and returns a new semaphore with the counter initially set to `init`.
export
makeSemaphore : HasIO io => Int -> io Semaphore
makeSemaphore init = primIO (prim__makeSemaphore init)

||| Increments the semaphore's internal counter.
export
semaphorePost : HasIO io => Semaphore -> io ()
semaphorePost sema = primIO (prim__semaphorePost sema)

||| Blocks until the internal counter for semaphore sema is non-zero. When the
||| counter is non-zero, it is decremented and `semaphoreWait` returns.
export
semaphoreWait : HasIO io => Semaphore -> io ()
semaphoreWait sema = primIO (prim__semaphoreWait sema)


-- Barriers

||| A barrier enables multiple threads to synchronize the beginning of some
||| computation.
export
data Barrier : Type where [external]

%foreign "scheme:blodwen-make-barrier"
prim__makeBarrier : Int -> PrimIO Barrier
%foreign "scheme:blodwen-barrier-wait"
prim__barrierWait : Barrier -> PrimIO ()

||| Creates a new barrier that can block a given number of threads.
|||
||| @ numThreads the number of threads to block
export
makeBarrier : HasIO io => (numThreads : Int) -> io Barrier
makeBarrier numThreads = primIO (prim__makeBarrier numThreads)

||| Blocks the current thread until all threads have rendezvoused here.
export
barrierWait : HasIO io => Barrier -> io ()
barrierWait barrier = primIO (prim__barrierWait barrier)


-- Channels

export
data Channel : Type -> Type where [external]

data ChannelObj : Type where [external]

data ChannelSchemeObj : Type where
  Null       : ChannelSchemeObj
  Cons       : ChannelSchemeObj -> ChannelSchemeObj -> ChannelSchemeObj
  IntegerVal : Integer -> ChannelSchemeObj
  FloatVal   : Double -> ChannelSchemeObj
  StringVal  : String -> ChannelSchemeObj
  CharVal    : Char -> ChannelSchemeObj
  Symbol     : String -> ChannelSchemeObj
  Box        : ChannelSchemeObj -> ChannelSchemeObj
  Vector     : Integer -> List ChannelSchemeObj -> ChannelSchemeObj
  Procedure  : ChannelObj -> ChannelSchemeObj

export
interface Scheme a where
  fromScheme : ChannelSchemeObj -> Maybe a

export
Scheme Integer where
  fromScheme (IntegerVal x) = Just x
  fromScheme _              = Nothing

export
Scheme Nat where
  fromScheme (IntegerVal x) = Just $ integerToNat x
  fromScheme _              = Nothing

export
Scheme Int where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Int8 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Int16 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Int32 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Int64 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Bits8 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Bits16 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Bits32 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme Bits64 where
  fromScheme (IntegerVal x) = Just (cast x)
  fromScheme _              = Nothing

export
Scheme String where
  fromScheme (StringVal x) = Just x
  fromScheme _             = Nothing

export
Scheme Double where
  fromScheme (FloatVal x) = Just x
  fromScheme _            = Nothing

export
Scheme Char where
  fromScheme (CharVal x) = Just x
  fromScheme _           = Nothing

export
Scheme Bool where
  fromScheme (IntegerVal 0) = Just False
  fromScheme (IntegerVal 1) = Just True
  fromScheme _              = Nothing

export
Scheme a => Scheme (List a) where
  fromScheme Null        = Just []
  fromScheme (Cons x xs) = Just $ !(fromScheme x) :: !(fromScheme xs)
  fromScheme _           = Nothing

export
(Scheme a, Scheme b) => Scheme (a, b) where
  fromScheme (Cons x y) = Just (!(fromScheme x), !(fromScheme y))
  fromScheme _          = Nothing

export
Scheme a => Scheme (Maybe a) where
  fromScheme Null    = Just Nothing
  fromScheme (Box x) = Just $ Just !(fromScheme x)
  fromScheme _       = Nothing

%foreign "scheme:blodwen-is-number"
prim_isNumber : ChannelObj -> Int
%foreign "scheme:blodwen-is-integer"
prim_isInteger : ChannelObj -> Int
%foreign "scheme:blodwen-is-float"
prim_isFloat : ChannelObj -> Int
%foreign "scheme:blodwen-is-char"
prim_isChar : ChannelObj -> Int
%foreign "scheme:blodwen-is-string"
prim_isString : ChannelObj -> Int
%foreign "scheme:blodwen-is-procedure"
prim_isProcedure : ChannelObj -> Int
%foreign "scheme:blodwen-is-symbol"
prim_isSymbol : ChannelObj -> Int
%foreign "scheme:blodwen-is-nil"
prim_isNil : ChannelObj -> Int
%foreign "scheme:blodwen-is-pair"
prim_isPair : ChannelObj -> Int
%foreign "scheme:blodwen-is-vector"
prim_isVector : ChannelObj -> Int
%foreign "scheme:blodwen-id"
unsafeGetInteger : ChannelObj -> Integer
%foreign "scheme:blodwen-id"
unsafeGetString : ChannelObj -> String
%foreign "scheme:blodwen-id"
unsafeGetFloat : ChannelObj -> Double
%foreign "scheme:blodwen-id"
unsafeGetChar : ChannelObj -> Char
%foreign "scheme:car"
unsafeFst : ChannelObj -> ChannelObj
%foreign "scheme:cdr"
unsafeSnd : ChannelObj -> ChannelObj
%foreign "scheme:blodwen-vector-ref"
unsafeVectorRef : ChannelObj -> Integer -> ChannelObj
%foreign "scheme:blodwen-unbox"
unsafeUnbox : ChannelObj -> ChannelObj
%foreign "scheme:blodwen-vector-length"
unsafeVectorLength : ChannelObj -> Integer
%foreign "scheme:blodwen-vector-list"
unsafeVectorToList : ChannelObj -> List ChannelObj
%foreign "scheme:blodwen-read-symbol"
unsafeReadSymbol : ChannelObj -> String
%foreign "scheme:blodwen-is-box"
prim_isBox : ChannelObj -> Int
%foreign "scheme:blodwen-make-channel"
prim__makeChannel : PrimIO (Channel a)
%foreign "scheme:blodwen-channel-get"
prim__channelGet : Channel a -> PrimIO a
%foreign "scheme:blodwen-channel-get-non-blocking"
prim__channelGetNonBlocking : Channel a -> PrimIO ChannelObj
%foreign "scheme:blodwen-channel-get-with-timeout"
prim__channelGetWithTimeout : Channel a -> Nat -> PrimIO ChannelObj
%foreign "scheme:blodwen-channel-put"
prim__channelPut : Channel a -> a -> PrimIO ()

||| Creates and returns a new `Channel`.
|||
||| The channel can be used with `channelGet` to receive a value through the
||| channel.
||| The channel can be used with `channelPut` to send a value through the
||| channel.
export
makeChannel : HasIO io => io (Channel a)
makeChannel = primIO prim__makeChannel

||| Blocks until a sender is ready to provide a value through `chan`. The result
||| is the sent value.
|||
||| @ chan the channel to receive on
export
channelGet : HasIO io => (chan : Channel a) -> io a
channelGet chan = primIO (prim__channelGet chan)

||| Non-blocking version of channelGet.
|||
||| @ chan the channel to receive on
partial
export
channelGetNonBlocking : HasIO io => Scheme a => (chan : Channel a) -> io (Maybe a)
channelGetNonBlocking chan =
  pure $ (fromScheme . decodeObj) !(primIO (prim__channelGetNonBlocking chan))
  where
    decodeObj : ChannelObj -> ChannelSchemeObj
    decodeObj obj =
      if prim_isInteger obj == 1 then IntegerVal (unsafeGetInteger obj)
      else if prim_isVector obj == 1 then Vector (unsafeGetInteger (unsafeVectorRef obj 0))
                                                 (readVector (unsafeVectorLength obj) 1 obj)
      else if prim_isPair obj == 1 then Cons (decodeObj (unsafeFst obj))
                                             (decodeObj (unsafeSnd obj))
      else if prim_isFloat obj == 1 then FloatVal (unsafeGetFloat obj)
      else if prim_isString obj == 1 then StringVal (unsafeGetString obj)
      else if prim_isChar obj == 1 then CharVal (unsafeGetChar obj)
      else if prim_isSymbol obj == 1 then Symbol (unsafeReadSymbol obj)
      else if prim_isProcedure obj == 1 then Procedure obj
      else if prim_isBox obj == 1 then Box (decodeObj (unsafeUnbox obj))
      else Null
      where
        readVector : Integer -> Integer -> ChannelObj -> List ChannelSchemeObj
        readVector len i obj
          = if len == i
              then []
              else decodeObj (unsafeVectorRef obj i) :: readVector len (i + 1) obj

||| Timeout version of channelGet.
||| Continously loops with 1ms delays until `seconds` has elapsed, or a value is provided through `chan`.
|||
||| @ chan the channel to receive on
||| @ seconds how many seconds to wait until timeout
partial
export
channelGetWithTimeout : HasIO io => Scheme a => (chan : Channel a) -> (seconds : Nat) -> io (Maybe a)
channelGetWithTimeout chan seconds =
  pure $ (fromScheme . decodeObj) !(primIO (prim__channelGetWithTimeout chan seconds))
  where
    decodeObj : ChannelObj -> ChannelSchemeObj
    decodeObj obj =
      if prim_isInteger obj == 1 then IntegerVal (unsafeGetInteger obj)
      else if prim_isVector obj == 1 then Vector (unsafeGetInteger (unsafeVectorRef obj 0))
                                                 (readVector (unsafeVectorLength obj) 1 obj)
      else if prim_isPair obj == 1 then Cons (decodeObj (unsafeFst obj))
                                             (decodeObj (unsafeSnd obj))
      else if prim_isFloat obj == 1 then FloatVal (unsafeGetFloat obj)
      else if prim_isString obj == 1 then StringVal (unsafeGetString obj)
      else if prim_isChar obj == 1 then CharVal (unsafeGetChar obj)
      else if prim_isSymbol obj == 1 then Symbol (unsafeReadSymbol obj)
      else if prim_isProcedure obj == 1 then Procedure obj
      else if prim_isBox obj == 1 then Box (decodeObj (unsafeUnbox obj))
      else Null
      where
        readVector : Integer -> Integer -> ChannelObj -> List ChannelSchemeObj
        readVector len i obj
          = if len == i
              then []
              else decodeObj (unsafeVectorRef obj i) :: readVector len (i + 1) obj

||| Puts a value on the given channel.
|||
||| @ chan the `Channel` to send the value over
||| @ val  the value to send
export
channelPut : HasIO io => (chan : Channel a) -> (val : a) -> io ()
channelPut chan val = primIO (prim__channelPut chan val)
