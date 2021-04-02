{-# language DataKinds #-}
{-# language DeriveTraversable #-}
{-# language DerivingStrategies #-}
{-# language GeneralizedNewtypeDeriving #-}
{-# language NamedFieldPuns #-}
{-# language StandaloneKindSignatures #-}
{-# language TypeFamilies #-}
{-# language UndecidableInstances #-}

{-# options_ghc -fno-warn-redundant-constraints #-}

module Rel8.Type.Array1D
  ( Array1D( Array1D )
  , getArray1D
  )
where

-- aeson
import Data.Aeson
  ( ToJSON
  , ToJSON1
  , ToJSONKey
  , FromJSON
  , FromJSON1
  , FromJSONKey
  )

-- base
import Control.Applicative ( Alternative, (<|>) )
import Control.Monad ( MonadPlus )
import Data.Functor.Classes ( Eq1, Ord1, Read1, Show1 )
import Data.Kind ( Type )
import GHC.Exts ( IsList )
import Prelude hiding ( null )

-- hasql
import qualified Hasql.Decoders as Hasql

-- opaleye
import qualified Opaleye.Internal.HaskellDB.PrimQuery as Opaleye

-- rel8
import Rel8.Expr.Opaleye ( zipPrimExprsWith )
import Rel8.Expr.Serialize ( litExpr )
import Rel8.Schema.Nullability
  ( Unnullify
  , Nullability( Nullable, NonNullable )
  , Sql, nullabilization
  )
import Rel8.Type ( DBType, typeInformation )
import Rel8.Type.Eq ( DBEq )
import Rel8.Type.Information ( TypeInformation(..) )
import Rel8.Type.Monoid ( DBMonoid, memptyExpr )
import Rel8.Type.Ord ( DBMax, DBMin, DBOrd )
import Rel8.Type.Semigroup ( DBSemigroup, (<>.) )

-- semigroupoids
import Data.Functor.Alt ( Alt, (<!>) )
import Data.Functor.Apply ( Apply )
import Data.Functor.Bind ( Bind )
import Data.Functor.Plus ( Plus )

-- semialign
import Data.Align ( Align )
import Data.Semialign ( Semialign )
import Data.Zip ( Repeat, Unzip, Zip )


newtype Array1D a = Array1D [a]
  deriving stock Traversable
  deriving newtype
    ( Eq, Ord, Read, Show, Semigroup, Monoid, IsList
    , Functor, Foldable
    , Eq1, Ord1, Read1, Show1
    , FromJSON1, ToJSON1, FromJSON, FromJSONKey, ToJSON, ToJSONKey
    , Apply, Applicative, Alternative, Plus, Bind, Monad, MonadPlus
    , Align, Semialign, Repeat, Unzip, Zip
    )


instance Alt Array1D where
  (<!>) = (<|>)


getArray1D :: Array1D a -> [a]
getArray1D (Array1D a) = a


type IsArray1D :: Type -> Bool
type family IsArray1D a where
  IsArray1D (Array1D _) = 'True
  IsArray1D _ = 'False


array1DTypeInformation :: IsArray1D (Unnullify a) ~ 'False
  => Nullability a
  -> TypeInformation (Unnullify a)
  -> TypeInformation (Array1D a)
array1DTypeInformation nullability info = 
  case info of
    TypeInformation{ encode, decode, typeName, out } -> TypeInformation
      { decode = case nullability of
          Nullable -> Array1D <$> Hasql.listArray (Hasql.nullable (out <$> decode))
          NonNullable -> Array1D <$> Hasql.listArray (Hasql.nonNullable (out <$> decode))
      , encode = case nullability of
          Nullable -> Opaleye.ArrayExpr . fmap (maybe null encode) . getArray1D
          NonNullable -> Opaleye.ArrayExpr . fmap encode . getArray1D
      , typeName = typeName <> "[]"
      , out = id
      }
  where
    null = Opaleye.ConstExpr Opaleye.NullLit


instance (Sql DBType a, IsArray1D (Unnullify a) ~ 'False) => DBType (Array1D a) where
  typeInformation = array1DTypeInformation nullabilization typeInformation


instance (Sql DBEq a, IsArray1D (Unnullify a) ~ 'False) => DBEq (Array1D a)


instance (Sql DBOrd a, IsArray1D (Unnullify a) ~ 'False) => DBOrd (Array1D a)


instance (Sql DBMax a, IsArray1D (Unnullify a) ~ 'False) => DBMax (Array1D a)


instance (Sql DBMin a, IsArray1D (Unnullify a) ~ 'False) => DBMin (Array1D a)


instance (Sql DBType a, IsArray1D (Unnullify a) ~ 'False) => DBSemigroup (Array1D a) where
  (<>.) = zipPrimExprsWith (Opaleye.BinExpr (Opaleye.:||))


instance (Sql DBType a, IsArray1D (Unnullify a) ~ 'False) => DBMonoid (Array1D a) where
  memptyExpr = litExpr mempty