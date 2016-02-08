module Event.Connection where

import Utils.PreludePlus
import BatchConnector.Connection (WebMessage)
import Data.Aeson (ToJSON, toJSON)

data Event = Message { _message :: WebMessage }
           | Opened
           | Closed  { _code :: Int }
           | Error
             deriving (Eq, Show, Typeable, Generic)

makeLenses ''Event

instance PrettyPrinter Event where
    display (Message m)   = show m
    display Opened        = "Opened"
    display (Closed code) = "Closed " <> (show code)
    display Error         = "Error"

instance ToJSON Event
instance ToJSON WebMessage where
    toJSON _ = toJSON "(..)"
