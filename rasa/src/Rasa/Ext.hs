{-# LANGUAGE Rank2Types, FlexibleContexts #-}

----------------------------------------------------------------------------
-- |
-- Module      :  Rasa.Ext
-- Copyright   :  (C) 2016 Chris Penner
-- License     :  MIT
-- Maintainer  :  Chris Penner <christopher.penner@gmail.com>
--
-- This module contains the public API for building an extension for Rasa. It
-- re-exports the parts of rasa that are public API for creating extensions.
--
-- There are two main things that an extension can do, either react
-- to editor events, or expose useful actions and/or state for other extensions
-- to use.
--
-- To react to events an extension defines a 'Scheduler'
-- which the user puts in their config file. The 'Scheduler'
-- defines listeners for events which the extension will react to.
-- See 'Scheduler' for more detailed information.
--
-- Whether performing its own actions or being used by a different extension
-- an extension will want to define some 'Action's to perform. Actions
-- can operate over buffers or even perform IO and comprise the main way in which
-- extensons do what they need to do. Read more here: 'Action', 'BufAction'.
--
-- To sum it all up, Here's an example of a simple logging extension that
-- simply writes each keypress to a file.
--
-- > logKeypress :: Keypress -> Action ()
-- > logKeypress (Keypress char _) = liftIO $ appendFile "logs" ("You pressed " ++ [char] ++ "\n")
-- >
-- > logger :: Scheduler ()
-- > logger = do
-- >   onInit $ liftIO $ writeFile "logs" "==Logs==\n"
-- >   eventListener logKeypress
-- >   onExit $ liftIO $ appendFile "logs" "==Done=="
--
-- Check out this tutorial on building extensions, it's also just a great way to learn
-- how the editor works: <https://github.com/ChrisPenner/rasa/blob/master/docs/Building-An-Extension.md Building an
-- Extension>.
----------------------------------------------------------------------------

module Rasa.Ext
  (
  -- * Editor Actions
    Action
  , exit
  , addBuffer
  , addBufferThen
  , nextBuf
  , prevBuf

  -- * Buffer Actions
  , BufAction
  , bufDo
  , focusDo
  , overRange
  , replaceRange
  , deleteRange
  , insertAt
  , sizeOf

  -- * Persisting Extension State
  -- | Extension states for ALL the extensions installed are stored in the same
  -- map keyed by their 'Data.Typeable.TypeRep' so if more than one extension
  -- uses the same type then they'll conflict. This is easily solved by simply
  -- using a newtype around any types which other extensions may use (your own
  -- custom types don't need to be wrapped). For example if your extension stores
  -- a counter as an Int, wrap it in your own custom Counter newtype when storing
  -- it.
  --
  -- Because Extension states are stored by their TypeRep, they must define an
  -- instance of Typeable, luckily GHC can derive this for you.
  --
  -- It is also required for all extension states to define an instance of
  -- 'Data.Default.Default', this is because accessing an extension which has not
  -- yet been stored will result in the default value.
  --
  -- If there's no default value that makes sense for your type, you can define
  -- a default of 'Data.Maybe.Nothing' and pattern match on its value when you
  -- access it.
  --
  -- Extensions may store state persistently for later access or for other
  -- extensions to access. Because Rasa can't possibly know the types of the
  -- state that extensions will store it uses a clever workaround wherein
  -- extension states are stored in a map of 'Data.Typeable.TypeRep' -> Ext
  -- which is coerced into the proper type when it's extracted. The interface to
  -- extract or alter a given extension is to use the 'ext' and 'bufExt' lenses.
  -- Simply use them as though they were lenses to an object of your type and
  -- it'll all work out.
  --
  -- Since it's polymorphic, if ghc can't figure out the type the result is
  -- supposed to be then you'll need to help it out. In practice you won't
  -- typically need to do this unless you're doing something complicated.

  , ext
  , bufExt

   -- * Accessing/Editing Context
  , Buffer
  , text
  -- | A lens over the buffer's 'Data.Text.Text'. Use within a 'BufAction' as
  --
  -- > txt <- use text

  , exiting
  -- | A lens over the current 'exit' status of the editor, allows an extension to
  -- signal the editor to shutdown. If this is set the current events will finish processing, then the
  --
  -- 'Rasa.Ext.Events.Exit' event will be dispatched, then the editor will exit.
  -- Use within an 'Action'
  --
  -- > exiting .= True

  -- * Events
  , Keypress(..)
  , Mod(..)

  -- * Dealing with events
  , Scheduler
  , Hooks
  , Hook
  , dispatchEvent
  , eventListener

  -- * Built-in Event Hooks
  , onInit
  , beforeEvent
  , beforeRender
  , onRender
  , afterRender
  , onExit

   -- * Ranges
  , Range(..)
  , Coord(..)
  , Offset(..)
  , Span(..)
  , combineSpans
  , asCoord
  , clampCoord
  , clampRange
  , range
  , sizeOfR
  , afterC
  , beforeC
  , moveRange
  , moveRangeByN
  , moveCursorByN

   -- * Useful Utilities
  , asText
  , asString
  , asLines
  , rope
  , clamp
  ) where

import Rasa.Internal.Action
import Rasa.Internal.Directive
import Rasa.Internal.Editor
import Rasa.Internal.Events
import Rasa.Internal.Buffer
import Rasa.Internal.Text
import Rasa.Internal.Range
import Rasa.Internal.Scheduler
