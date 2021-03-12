{-# language DataKinds #-}
{-# language FlexibleContexts #-}
{-# language FlexibleInstances #-}
{-# language StandaloneKindSignatures #-}
{-# language TypeFamilies #-}

module Rel8.Table.Lifted
  ( Table1( Columns1, ConstrainContext1, toColumns1, fromColumns1 )
  , Table2( Columns2, ConstrainContext2, toColumns2, fromColumns2 )
  )
where

-- base
import Data.Kind ( Constraint, Type )
import Prelude ()

-- rel8
import Rel8.Schema.HTable ( HTable )
import Rel8.Schema.HTable.Context ( H, HKTable )
import Rel8.Schema.HTable.Bifunctor ( HBifunctor )
import Rel8.Schema.HTable.Functor ( HFunctor )
import Rel8.Schema.Spec ( Context )


type Table1 :: (Type -> Type) -> Constraint
class HFunctor (Columns1 f) => Table1 f where
  type Columns1 f :: HKTable -> HKTable
  type ConstrainContext1 f :: Context -> Constraint
  type ConstrainContext1 _ = DefaultConstrainContext

  toColumns1 :: (ConstrainContext1 f context, HTable t)
    => (a -> t (H context))
    -> f a
    -> Columns1 f t (H context)
  fromColumns1 :: (ConstrainContext1 f context, HTable t)
    => (t (H context) -> a)
    -> Columns1 f t (H context)
    -> f a


type Table2 :: (Type -> Type -> Type) -> Constraint
class HBifunctor (Columns2 p) => Table2 p where
  type Columns2 p :: HKTable -> HKTable -> HKTable
  type ConstrainContext2 p :: Context -> Constraint
  type ConstrainContext2 _ = DefaultConstrainContext

  toColumns2 :: (ConstrainContext2 p context, HTable t, HTable u)
    => (a -> t (H context))
    -> (b -> u (H context))
    -> p a b
    -> Columns2 p t u (H context)
  fromColumns2 :: (ConstrainContext2 p context, HTable t, HTable u)
    => (t (H context) -> a)
    -> (u (H context) -> b)
    -> Columns2 p t u (H context)
    -> p a b


type DefaultConstrainContext :: Context -> Constraint
class DefaultConstrainContext context
instance DefaultConstrainContext context