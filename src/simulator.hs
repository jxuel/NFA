import System.Environment
import System.IO

{-# OPTIONS_GHC -fwarn-incomplete-paterns #-}
type State = Int
type Final_States = [Int]
type States = [Int]
type Alphabet = [Char]
type Transiton = [[(Int,Int,Int)]]
type NFA a = (States, Alphabet, Transiton, State, Final_States)

--Get the number at the end of a line after a space
--Return a list of the integer from 0 to the number
setStates :: String -> [Int]
setStates [] = []
setStates (h:nxt:t)
    | h == ':' = [0..((read t :: Int)-1)]
    | otherwise = setStates (nxt:t)

--Get the number at the end of a line after a space
--Return a integer
setAlphabet :: String -> [Char]
setAlphabet [] = []
setAlphabet (h:nxt:t)
    | h == ':' = take (read t :: Int) ['a'..'z']
    | otherwise = setAlphabet (nxt:t)

--Get numbers after whitspace
--Return all numbers in a list of integer
setAcStates :: String -> [Int]
setAcStates [] = []
setAcStates (h:t)
    | h == ' ' && t == [] = [] 
    | h == ' ' && (head t) /= 's' = (if (length t > 1 && (head (tail t)) /= ' ') then (read ((head t):(head (tail t)):[])::Int):(setAcStates t) else (read ((head t):[])::Int):(setAcStates t))
    | otherwise = setAcStates t

--Set transitions
--Return (Current State, w, Next State)
setTransition :: String -> Int -> Int -> [(Int,Int,Int)]
setTransition [] _ _= []
setTransition input alpha st
    | h == '{' || h == ',' ||  h == ' ' = setTransition t alpha st
    | h == '}' = setTransition t (alpha+1) st
    | n == ',' || n == '}' = do
        (st, alpha,(read (h:[])::Int)) : setTransition t alpha st
    | otherwise =do
        (st, alpha,(read (h:n:[])::Int)): setTransition nt alpha st
    where
        h = head input
        t = tail input
        n = head t
        nt = tail t

--Construct a new NFA with initial state at 0
--Return an NFA (States, Alphabet, Transiton, State, Final_States)
initializeNFA :: States -> Alphabet ->Transiton -> States -> NFA a
initializeNFA sts alphabet transitions finalStates = (sts, alphabet, transitions, 0, finalStates)

--Change ['a'..'z'] to [0..25]
--Return a Char's correspond to the order of alphabet integer
charToInt :: Char -> Int
charToInt i = snd ((filter (\(c,_) -> c == i) (zip['a'..'z'][0..25])) !! 0)

--Find available path to move according to the start state and char
--Return list of destinations or empty list
moveTo :: [(Int,Int,Int)] -> Char -> [Int]
moveTo trans condition = filter (/= -1) (map (\inp@(inST, alpha, outST) -> if alpha == (charToInt condition) then outST else -1) trans)

--Evaluate a string by using current nfa
--The procedure will evaluate all possible path. If there is at least one path accepted, the string is accepted
--Return True if accepted otherwise False
evalInputs :: NFA a -> String -> Bool
evalInputs nfa@(sts, alphabet, [], initSt, finalStates) _ = False
evalInputs nfa@(sts, alphabet, transitions, initSt, finalStates) [] = length (filter (==initSt) finalStates) == 1
evalInputs nfa@(sts, alphabet, transitions, initSt, finalStates) input@(h:t)
    | length availablePath > 1 = if (length (filter (==True) (map (\ nxt_st -> evalInputs (sts, alphabet, transitions, nxt_st, finalStates) t ) availablePath)) > 0) then True else False  
    | length availablePath == 0 = False
    | otherwise = evalInputs (sts, alphabet, transitions, (availablePath !! 0), finalStates) t
    where
        current_Trans = transitions !! initSt
        availablePath = moveTo current_Trans h 
        isFinalST =  (length (filter (==initSt) finalStates) == 1)

--Out put the string and the result
--Return string followed by Accept or Reject
outputResults :: (String, Bool) -> IO ()
outputResults (_, result) = putStrLn (if result then " accept" else " reject")

main :: IO ()
main = do
--Read files
        [inNFA]<- getArgs
        strContent <- getContents
        nfaContent <- readFile inNFA
        let nfaLine = lines nfaContent
        let strLine = lines strContent

--Build NFA
        let states = setStates (nfaLine !! 0)
        let alpha = setAlphabet (nfaLine !! 1)
        let acStates = setAcStates (nfaLine !! 2)
        let trans = filter (\(h:t) -> h == '{') nfaLine
        let transitions = map (\(st,tr) -> setTransition tr (-1) (st)) (zip states trans)
        let initNFA = initializeNFA states alpha transitions acStates

--Eval strings
        let results = zip strLine (map (evalInputs initNFA) strLine)
        mapM_ outputResults results
