import System
import System.Concurrency

-- Simple producing thread.
producer : Channel Nat -> Nat -> IO ()
producer c n = ignore $ producer' n
  where
    producer' : Nat -> IO ()
    producer' Z     = pure ()
    producer' (S n) = do
      channelPut c n
      sleep 1

-- Test that channelGetWithTimeout works as expected.
main : IO ()
main =
  do c    <- makeChannel
     tids <- for [0..11] $ \n => fork $ producer c n
     vals <- for [0..11] $ \_ => channelGetWithTimeout c 5
     ignore $ traverse (\t => threadWait t) tids
     let vals' = map (\val => case val of
                        Nothing   =>
                          0
                        Just val' =>
                          val'
                     ) vals
         s     = sum vals'
     if s == 55
        then putStrLn "Success!"
        else putStrLn "How did we get here?"

