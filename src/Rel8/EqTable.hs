{-# language FlexibleInstances #-}
{-# language ScopedTypeVariables #-}
{-# language TypeApplications #-}
{-# language UndecidableInstances #-}

module Rel8.EqTable where

import Control.Applicative
import Data.Proxy
import Rel8.Column
import Rel8.DBEq
import Rel8.Expr
import Rel8.HigherKinded
import Rel8.Table


-- | The class of database tables (containing one or more columns) that can be
-- compared for equality as a whole.
class Table a => EqTable a where
  (==.) :: a -> a -> ExprIn a Bool


-- | Any @Expr@s can be compared for equality as long as the underlying
-- database type supports equality comparisons.
instance DBTypeEq a => EqTable ( Expr m a ) where
  (==.) =
    eqExprs


-- | Higher-kinded records can be compared for equality. Two records are equal
-- if all of their fields are equal.
instance ( ZipRecord t ( Expr m ) ( Expr m ) DBTypeEq, HigherKinded t ) => EqTable ( t ( Expr m ) ) where
  l ==. r =
    foldl
      (&&.)
      ( lit True )
      ( getConst
          ( zipRecord
              @_
              @DBTypeEq
              @_
              @(Expr m)
              Proxy
              ( \( C a ) ( C b ) -> Const [ eqExprs a b ] )
              l
              r
          )
      )
