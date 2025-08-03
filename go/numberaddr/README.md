## numberaddr ##

The application is given two arbitrarily large numbers,
stored one digit at a time in a slice.
The first must be added to the second,
and the second must be reversed before addition.

The goal is to calculate the sum of those two sets of values.

IMPORTANT NOTE:
- The input can be any lengths (i.e: it can be 20+ digits long).
- num1 and num2 can be different lengths.

Sample Inputs:
num1 = 123456
num2 = 123456

Sample Output:
Result: 777777

The application generates a random set of test values.

A demonstration of appropriate unit tests for this functionality is provided.


## Sample Output ##

	 Number 1                       | Number 2                       | Reversed Number 2              | Result
	 -------------------------------|--------------------------------|--------------------------------|-------------------------------
	 06027027006                    | 537445562340147383             | 383741043265544735             | 383741049292571741
	 404361066208                   | 177471                         | 174771                         | 404361240979
	 88761                          | 2607607345056478763374268064   | 4608624733678746505437067062   | 4608624733678746505437155823
	 44404575700272308138           | 42602247407586853627620875123  | 32157802672635868570474220624  | 32157802717040444270746528762
	 468367                         | 84525                          | 52548                          | 520915
	 10320035587716                 |                                |                                | 10320035587716
	 717024445278210                | 086577                         | 775680                         | 717024446053890
	 431246                         | 73441586080                    | 08068514437                    | 08068945683
	 88338332738711885134247        | 301177153080421457071          | 170754124080351771103          | 88509086862792236905350
	 22708232471563420484728        | 21464408656601                 | 10665680446412                 | 22708232482229100931140
	 7116041675711                  | 122774167318321107008          | 800701123813761477221          | 800701130929803152932
	 213                            | 7045008088053107414355551      | 1555534147013508808005407      | 1555534147013508808005620
	 421030054838365448732371585    | 186164                         | 461681                         | 421030054838365448732833266
	 838                            | 634838801254055632080          | 080236550452108838436          | 080236550452108839274
	 703416230210266                | 313                            | 313                            | 703416230210579
									| 15850                          | 05851                          | 05851
	 052272208165                   | 54382873165746                 | 64756137828345                 | 64808410036510
	 363866625686830833637512156    | 2385664                        | 4665832                        | 363866625686830833642177988
	 60526201336238713870715        | 6561350475122                  | 2215740531656                  | 60526201338454454402371
	 24832627                       | 3112575843883253804872         | 2784083523883485752113         | 2784083523883510584740

## Test out ##

=== RUN   TestBasic
--- PASS: TestBasic (0.00s)
=== RUN   TestVariablelength
=== RUN   TestVariablelength/"123456+123456"
=== RUN   TestVariablelength/"+"
=== RUN   TestVariablelength/"4+2"
=== RUN   TestVariablelength/"7+7"
=== RUN   TestVariablelength/"888+888"
=== RUN   TestVariablelength/"21168+"
=== RUN   TestVariablelength/"+21168"
=== RUN   TestVariablelength/"521711361115+50828"
=== RUN   TestVariablelength/"464057727650121415880523648+521734278488"
--- PASS: TestVariablelength (0.00s)
    --- PASS: TestVariablelength/"123456+123456" (0.00s)
    --- PASS: TestVariablelength/"+" (0.00s)
    --- PASS: TestVariablelength/"4+2" (0.00s)
    --- PASS: TestVariablelength/"7+7" (0.00s)
    --- PASS: TestVariablelength/"888+888" (0.00s)
    --- PASS: TestVariablelength/"21168+" (0.00s)
    --- PASS: TestVariablelength/"+21168" (0.00s)
    --- PASS: TestVariablelength/"521711361115+50828" (0.00s)
    --- PASS: TestVariablelength/"464057727650121415880523648+521734278488" (0.00s)
PASS
ok  	github.com/ebruno/codesamples/go/numberaddr	0.025s
