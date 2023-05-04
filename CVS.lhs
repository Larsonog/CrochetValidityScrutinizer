> {-# LANGUAGE GADTs #-}
> {-# OPTIONS_GHC -Wall #-}
> import Parsing2

  
CVS (Crochet Validity Scrutinizer)
==================================
All of these are common stitches that a beginner would find and are the building blocks
of all patterns and more complex stitches. 

> data Stitch where 
>   SlipStitch    :: Integer -> Stitch -- slip stitch
>   SingleCrochet :: Integer -> Stitch -- single crochet
>   DoubleCrochet :: Integer -> Stitch -- double crochet 
>   TrebleCrochet :: Integer -> Stitch -- treble corchet 
>   Space         :: Integer -> Stitch -- space
>   Chain         :: Integer -> Stitch -- chain 
>   deriving (Show, Eq)
> 

Parts are different because they can involve or build upon a stitch or is used to finish off or
flip the work. 

> data Part where 
>   S           :: Stitch -> Part
>   Increase    :: Integer -> Stitch -> Part -- increase in the pattern looks like (Increase 2 (SingleCrochet 1)) this means you put 5 singlecrochets in that stitch 
>   Decrease    :: Integer -> Stitch -> Part -- similarly decrease looks like (Decrease 2 (SingleCrochet 1)) this means you work 2 single crochets together, thus decreasing the width
>   FlipChain   :: Part -- flip chain is something you always do at the end of the row 
>   Flip        :: Part -- flip the piece
>   PullThrough :: Part -- finishes off the piece
>   deriving (Show, Eq)
> 
> type Row = [Part] -- Row is a list of parts that a pattern can be built off of 
> type Pattern = [Row] -- Pattern is a list of rows 

The pattern errors we chose are the ones that beginners are most likely to encounter. While some of these 
are technically allowed and used in higher level projects, its bad technique for beginners and they are most 
most likely to mess up their piece. 

> data PatternError where 
>   ZeroWidth   :: PatternError 
>   SpaceError  :: PatternError
>   DecError    :: PatternError 
>   IncError    :: PatternError -- old width, new width, error 
>   FlipEarly   :: PatternError 
>   BegSpace    :: PatternError 
>   NoTurnChain :: PatternError 
>   NoPull      :: PatternError  
>   TrebleError :: PatternError
>   WidthSize   :: PatternError
>   ProgFail    :: PatternError
>   deriving (Show)
> 
> showPatErr :: PatternError -> String 
> showPatErr ZeroWidth      = "The Width is Zero"
> showPatErr SpaceError     = "There are too many spaces in this row, there are over 5 consecutively."
> showPatErr DecError       = "Too many stitches have been combined, you tried to combine more than two stitches together "
> showPatErr IncError       = "You tried to add too many stitches on top of this one" 
> showPatErr FlipEarly      = "Flipped before end of row"
> showPatErr BegSpace       = "Can't start a row with a space"
> showPatErr NoTurnChain    = "There is no turning chain"
> showPatErr NoPull         = "There was no pull through at the end"
> showPatErr TrebleError    = "You cannot have these two types next to each other."
> showPatErr WidthSize      = "The width is either too large or too small!"
> showPatErr ProgFail       = "Something went wrong within the program. Dunno about your pattern! Sorry!"
> showPatErr _              = "Uh I don't know what to do with this error, haven't accounted for it."
>
>
> showWidth :: Integer -> Integer -> String 
> showWidth o n = "the original width is: " ++ show(o) ++ " the new width is: " ++ show(n)
> 
> showBool :: Bool -> String 
> showBool True = "Great! Your pattern is valid!!!!!!!!!!!"
> showBool False = "Oh no! Your pattern is invalid! Sorry!"
> -- important variables to keep track of 
> -- similarity to arith interpreter, so need to create an environment. take in the width and keep track of it through the environment
> -- Parsers 
> lexer :: TokenParser u
> lexer = makeTokenParser $
>   emptyDef
>   { reservedOpNames = ["ss","sc", "dc", "tc", "sp", "ch", "repeat", "inc", "tog", "remaining", "fc", "fl", ",", "pt", ";"]}  
> 
> integer :: Parser Integer
> integer = getInteger lexer
>
>
> whiteSpace :: Parser ()
> whiteSpace = getWhiteSpace lexer
> 
> parens :: Parser a -> Parser a
> parens = getParens lexer
> 
> parseRow :: Parser Row
> parseRow = parsePart `sepBy` reservedOp ","
> parseRows :: Parser Pattern -- don't need this any more 
> parseRows = parseRow `sepBy` reservedOp ";"
> -- because we have this we can now implement width and the pullthrough errors. 
>
>
> --Need to add a special symbol that is recognized as the change between rows, such as ; 
> -- SemiSep1 might be useful.
>
> parseStitch:: Parser Stitch
> parseStitch =
>       SlipStitch <$> (integer <* reservedOp "ss")
>   <|> SingleCrochet <$> (integer <* reservedOp "dc")
>   <|> DoubleCrochet <$> (integer <* reservedOp "dc")
>   <|> TrebleCrochet <$> (integer <* reservedOp "tc")
>   <|> Chain <$> (integer <* reservedOp "ch")
>   <|> Space <$> (integer <* reservedOp "sp")
>   <|> parens parseStitch
> 
> parsePart :: Parser Part
> parsePart =
>       S <$> parseStitch
>   <|> Increase <$> integer <*> parseStitch <* reservedOp "inc" 
>   <|> Decrease <$> integer <*> parseStitch <* reservedOp "tog"
>   <|> FlipChain <$ reservedOp "fc"
>   <|> Flip <$ reservedOp "fl"
>   <|> PullThrough <$ reservedOp "pt"


> -- does this pull from our lexer?

> reserved, reservedOp :: String -> Parser ()
> reserved   = getReserved lexer
> reservedOp = getReservedOp lexer
> 

> checkTreble :: Part -> Part -> Bool 
> checkTreble (S (TrebleCrochet _)) (S (SlipStitch _))  = True  
> checkTreble (S (TrebleCrochet _)) (S (SingleCrochet _))  = True
> checkTreble (S (SlipStitch _)) (S (TrebleCrochet _))  = True
> checkTreble (S (SingleCrochet _)) (S (TrebleCrochet _))  = True
> checkTreble _ _ = False 
> 
> checkFlip :: Part -> Bool
> checkFlip Flip = True 
> checkFlip _ = False
> 
> checkSpace :: Part -> Bool
> checkSpace (S (Space x)) = if x <= 5 then True else False
> checkSpace _ = False
>
> parse2 :: Parser Part
> parse2 = whiteSpace *> parsePart <* eof

> checkFC :: Part -> Bool 
> checkFC FlipChain = True 
> checkFC _ = False 
>
> lastRow :: Pattern -> Row
> lastRow pattern = lastRow pattern
>  
> checkPullThrough :: Part -> Pattern -> Bool 
> checkPullThrough PullThrough [] = False
> checkPullThrough PullThrough pattern = if last(last pattern) == PullThrough then False  else True
> checkPullThrough _ _ = True 
> 
> checkFlipChain :: Part -> [Part] -> Bool
> checkFlipChain FlipChain (x: parts) = if FlipChain == x then False else checkFlipChain FlipChain parts
> checkFlipChain _ _ = True
> 
> checkBegSpace :: Part -> [Part] -> Bool
> checkBegSpace (S(Space y ))(x: parts) = (S (Space y)) == x
> checkBegSpace _ _ = False 
>
> checkInc :: Part -> Bool
> checkInc (Increase y (SingleCrochet _)) = if y>2 then True else False
> checkInc (Increase y (DoubleCrochet _)) = if y>2 then True else False
> checkInc (Increase y (TrebleCrochet _)) = if y>2 then True else False
> checkInc (Increase y (SlipStitch    _)) = if y>2 then True else False
> checkInc  _ = False
>
> checkDec :: Part -> Bool
> checkDec (Decrease y (SingleCrochet _)) = if y>2 then True else False
> checkDec (Decrease y (DoubleCrochet _)) = if y>2 then True else False
> checkDec (Decrease y (TrebleCrochet _)) = if y>2 then True else False
> checkDec (Decrease y (SlipStitch    _)) = if y>2 then True else False
> checkDec  _ = False
> 
> checkChain :: Part -> Bool 
> checkChain (S(Chain _)) = True
> checkChain _ =  False
> 
> setUpOWid :: Part -> Integer
> setUpOWid (S(Chain x)) = x
> setUpOWid _ = 0
>
> setUpNWid :: Part -> Integer -> Integer
> setUpNWid (S(SingleCrochet x)) y = x + y
> setUpNWid (S(DoubleCrochet x)) y = x + y 
> setUpNWid (S(TrebleCrochet x)) y = x + y 
> setUpNWid (S(SlipStitch x)) y    = x + y 
> setUpNWid (S(Space x)) y         = x + y 
> setUpNWid (Increase x (_)) y     = x + y 
> setUpNWid (Decrease x (_)) y     = y - x
> setUpNWid _ y = y
> 
> checkWidth :: Integer -> Integer -> Bool
> checkWidth  o n
>   | n > 2 * o = True
>   | n < o `div` 2 = True 
> checkWidth _ _ = False
> 
> checkStitch :: Part -> Bool 
> checkStitch (Increase _ _) = True 
> checkStitch (Decrease _ _) = True
> checkStitch (S(SlipStitch _ )) = True
> checkStitch (S(SingleCrochet _ )) = True
> checkStitch (S(DoubleCrochet _ )) = True
> checkStitch (S(TrebleCrochet _ )) = True
> checkStitch _  = False
>

>
> data Progress where
>   Working :: Integer -> Integer -> Pattern -> Progress -- Add Integer -> Integer in the middle, Current Width -> Old Width. 
>   Done :: Bool -> Progress
>   Error :: PatternError -> Progress
> -- add the needed items for the environment to the Progress data type.
> -- Error ProgFail just accounts for the fact that the pattern may be vaild but something went wrong that isn't the users fault.
>

>
> step :: Progress -> Progress
> step (Working _ _[]) = Done True
> step (Done bool) = Done bool
> step (Working o n (r:pattern))  -- o is old width, n is new width
>   | checkBegSpace (S(Space 1)) (r) = Error BegSpace  -- works
>   | checkFlipChain FlipChain r = Error NoTurnChain -- works  CAN'T CHECK FLIPCHAIN AND PULL THROUGH AT SAME TIME
>   | checkPullThrough PullThrough pattern = Error NoPull  -- works 
>   | checkWidth o n = Error WidthSize
> step (Working o n ((x:p):pattern) ) 
>   | checkSpace x = Error SpaceError                  -- works 
>   | checkInc x  = Error IncError                     -- works 
>   | checkDec x = Error DecError                      -- works 
>   | checkChain x = Working (setUpOWid x) (setUpOWid x) pattern
>   | checkStitch x = Working o (setUpNWid x o) pattern
>   | checkWidth o n = Error WidthSize
> step (Working o n ((x:y:p):pattern))
>   | checkTreble x y = Error TrebleError              -- works
>   | checkStitch x  && checkStitch y  = Working o (((setUpNWid x o) +(setUpNWid y o) )) pattern 
>   | checkWidth o n = Error WidthSize

> -- turn the row cases into a guard case instead. Fixes infinite loop.
> -- Need to change the S Space of CheckBegSpace because it doesn't catch all cases currently.
> step (Error e) = Error e
> step _ = Done True
>  

> steps :: Progress -> Progress
> steps (Working o n pattern) = step (Working o n pattern)
> steps (Done bool) = Done bool
> steps _ = Error ProgFail

> execute :: Integer-> Integer -> Pattern -> Progress
> execute o n (pattern) = 
>    case step(Working o n pattern) of 
>        Working o n [] -> Done True
>        Working o' n' pattern' -> execute o' n' pattern'
>        Done bool -> Done bool 
>        Error e -> Error e
> 
> run :: Integer -> Integer -> Pattern -> String 
> run o n pattern = 
>   case execute o n pattern of 
>     Done True -> showBool True 
>     Done False -> showBool False -- we probably don't need it 
>     Error e -> showPatErr e   -- the cause of our problems
>     Working o n _ -> showBool False