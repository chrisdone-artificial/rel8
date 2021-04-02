{-# language DataKinds #-}

module Rel8.Query.Exists
  ( exists, inQuery
  , whereExists, with, withBy
  , whereNotExists, without, withoutBy
  )
where

-- base
import Prelude hiding ( filter )

-- opaleye
import qualified Opaleye.Operators as Opaleye

-- rel8
import Rel8.Expr ( Expr )
import Rel8.Query ( Query )
import Rel8.Query.Filter ( filter )
import Rel8.Query.Maybe ( optional )
import Rel8.Query.Opaleye ( mapOpaleye )
import Rel8.Table.Eq ( EqTable, (==:) )
import Rel8.Table.Maybe ( isJustTable )


-- | Checks if a query returns at least one row.
--
-- >>> :{
-- mapM_ print =<< select c do
--   author <- each authorSchema
--   hasProjects <- exists do
--     project <- each projectSchema
--     where_ $ authorId author ==. projectAuthorId project
--   return (authorName author, hasProjects)
-- :}
-- ("Ollie",True)
-- ("Bryan O'Sullivan",True)
-- ("Emily Pillmore",False)
exists :: Query a -> Query (Expr Bool)
exists = fmap isJustTable . optional . whereExists
-- FIXME: change this when b7aacc07c6392654cae439fc3b997620c3aa7a87 makes it
-- into a release of Opaleye


inQuery :: EqTable a => a -> Query a -> Query (Expr Bool)
inQuery a = exists . (>>= filter (a ==:))


-- | Produce the empty query if the given query returns no rows. @whereExists@
-- is equivalent to @WHERE EXISTS@ in SQL.
--
-- >>> :{
-- select c do
--   author <- each authorSchema
--   whereExists do
--     project <- each projectSchema
--     where_ $ projectAuthorId project ==. authorId author
--   return $ authorName author
-- :}
-- ["Ollie","Bryan O'Sullivan"]
whereExists :: Query a -> Query ()
whereExists = mapOpaleye Opaleye.restrictExists


-- | Produce the empty query if the given query returns rows. @whereNotExists@
-- is equivalent to @WHERE NOT EXISTS@ in SQL.
--
-- >>> :{
-- select c do
--   author <- each authorSchema
--   whereNotExists do
--     project <- each projectSchema
--     where_ $ projectAuthorId project ==. authorId author
--   return $ authorName author
-- :}
-- ["Emily Pillmore"]
whereNotExists :: Query a -> Query ()
whereNotExists = mapOpaleye Opaleye.restrictNotExists


with :: (a -> Query b) -> a -> Query a
with f a = a <$ whereExists (f a)


withBy :: (a -> b -> Expr Bool) -> Query b -> a -> Query a
withBy predicate bs = with $ \a -> bs >>= filter (predicate a)


without :: (a -> Query b) -> a -> Query a
without f a = a <$ whereNotExists (f a)


withoutBy :: (a -> b -> Expr Bool) -> Query b -> a -> Query a
withoutBy predicate bs = without $ \a -> bs >>= filter (predicate a)