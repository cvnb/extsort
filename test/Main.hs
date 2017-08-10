{-# LANGUAGE OverloadedStrings #-}

module Main ( main ) where

import           Data.External.Sort
import           Data.External.Tape

import           Control.Applicative
import           Control.Monad.Trans.Resource

--import           Data.Conduit
--import qualified Data.Conduit.Binary as C
--import qualified Data.Conduit.List as C

import           Data.Attoparsec.Binary
-- import           Data.Attoparsec.ByteString as Atto
import           Data.ByteString.Builder (word64LE) -- word64Host)
--import           Data.ByteString.Char8 (unpack)
import qualified Data.ByteString.Streaming.Char8 as BSS
import           Data.Attoparsec.ByteString.Char8 (decimal, satisfy)
import qualified Data.Attoparsec.ByteString.Streaming as AS
-- import qualified Data.ByteString.Internal as BS
--import           Data.Monoid
import           Data.String
import           Data.Char (isSpace)
--import           Data.Word (Word64)

-- import           Foreign.ForeignPtr
-- import           Foreign.Ptr
-- import           Foreign.Storable

import           System.Environment
import           System.IO
-- import           System.IO.Unsafe

import           Streaming
import qualified Streaming.Prelude as S

--import           Text.Read

-- word64HostP :: Parser Word64
-- word64HostP = do
--   x <- Atto.take 8
--   let ( bsPtr, bsOff, bsSz ) = BS.toForeignPtr x
--   if bsSz < 8 then fail "word64Host" else
--     pure . unsafePerformIO . withForeignPtr bsPtr $ \ptr ->
--       peek (ptr `plusPtr` bsOff)

main :: IO ()
main = do
  [input] <- getArgs

  let defaultOptions = SortOptions (10 * 1024) 7 100000 "sort.tmp" False
      intSerializers = Serializers anyWord64le word64LE
      noSerializer   = Serializers (pure ()) (const mempty)

      word64Parser = decimal <* many (satisfy (\c -> c /= '\n' && isSpace c)) <* satisfy (=='\n')

  runResourceT $
    BSS.toHandle stdout $
    BSS.unlines $
    maps (\((w, ()) :> next) -> fromString (show w) >> pure next) $
    externalSort defaultOptions compare intSerializers noSerializer noBytesCopy $
    S.map (,()) $
    AS.parsed word64Parser $
    BSS.readFile input
