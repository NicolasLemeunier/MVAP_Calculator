grammar TPPart1;

@members {
   private TablesSymboles tablesSymboles = new TablesSymboles();
   private int _cur_label = 1;
    /** générateur de nom d'étiquettes pour les boucles */
    private String getNewLabel() { return "Label" +(_cur_label++); }
    // ...
        }


calcul returns [ String code ]
@init{ $code = new String(); }   // On initialise code, pour ensuite l'utiliser comme accumulateur
@after{ System.out.println($code); }
    : (decl { $code += $decl.code; })*
      //{ $code += "  JUMP Main\n"; }
        NEWLINE*

        /*(fonction { $code += $fonction.code; })*
        NEWLINE*

        { $code += "LABEL Main\n"; }*/
        (instruction { $code += $instruction.code; })*

        { $code += "HALT\n"; }
    ;


instruction returns [ String code ]
    : a=expression finInstruction
        {
            $code = $a.code + "\n WRITE\n POP\n";
        }

    |   assignation finInstruction
        {
            $code = $assignation.code;
        }

    |   read finInstruction
        {
          $code = $read.code;
        }

    |   block finInstruction
        {
          $code = $block.code;
        }

    |   write finInstruction
        {
          $code = $write.code;
        }

    |   while_loop finInstruction
        {
          $code = $while_loop.code;
        }

    |   si finInstruction
        {
          $code = $si.code;
        }

    |   forLoop finInstruction
        {
          $code = $forLoop.code;
        }
    |   repeat finInstruction
        {
          $code = $repeat.code;
        }

   | finInstruction
        {
            $code="";
        }
    ;

expression returns [ String code ]
    : a=expression '+' b=expression {$code = $a.code + $b.code + "ADD\n";}
    | a=expression '-' b=expression {$code = $a.code + $b.code + "SUB\n";}
    | a=expression '*' b=expression {$code = $a.code + $b.code + "MUL\n";}
    | a=expression '/' b=expression {$code = $a.code + $b.code + "DIV\n";}
    | ENTIER {$code = "PUSHI " + $ENTIER.int + "\n";}
    | FLOTTANT {$code = "PUSHF " + $FLOTTANT.text + "\n";}
    | IDENTIFIANT {
            AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
            $code = "PUSHG " + at.adresse + "\n";
          }
  /*  | IDENTIFIANT '(' args ')'                  // appel de fonction
        {
            $code = "PUSHI 0 " + "PUSHI " + $arg.
        }*/
    ;

decl returns [ String code ]
    : 'var' IDENTIFIANT ':' TYPE finInstruction
        {
            if($TYPE.text.equals("int")){

              tablesSymboles.putVar($IDENTIFIANT.text,"int");
              AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
              {$code = "PUSHI " + 0 + "\n" + "STOREG " + at.adresse + "\n";}
            }
            else if($TYPE.text.equals("double")){

              tablesSymboles.putVar($IDENTIFIANT.text,"double");
              AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
              {$code = "PUSHF " + 0 + "\n" + "STOREG " + at.adresse + "\n";}
            }
        }

    | 'var' IDENTIFIANT ':' TYPE '=' expression finInstruction
      {
        tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);
        $code = $expression.code;
      }
    ;

assignation returns [ String code ]
    : IDENTIFIANT '=' expression
      {
          AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

          $code = $expression.code + "\n" + "STOREG " + at.adresse + "\n";
      }

    | IDENTIFIANT '+=' expression
      {
          AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

          $code = "PUSHG " + at.adresse + "\n" + $expression.code +  "ADD " + "\n" + "STOREG " + at.adresse + "\n";
      }
    ;
/*
fonction returns [ String code ]
@init{newTableLocale()} // instancier la table locale
@after{dropTableLocale()} // détruire la table locale
    : 'fun' IDENTIFIANT ':' TYPE
        {
            //  truc à faire par rapport au "type" de la fonction et code pour la "variable" de retour
            tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);
            AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
            $code = "PUSHI " + 0 + "\n" + "STOREL " + at.adresse + "\n";
	      }
        '('  params ? ')' block
        {
            $code = params.code
        }
    ;
*/
/*
params
    : TYPE IDENTIFIANT
        {
            tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);
            AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
            $code = "PUSHI 0" + "\n" + "STOREL " + at.adresse + "\n";
        }
        ( ',' TYPE IDENTIFIANT
            {
              tablesSymboles.putVar($IDENTIFIANT.text, $TYPE.text);
              AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);
              $code = "PUSHI 0" + "\n" + "STOREL " + at.adresse + "\n";
            }
        )*
    ;*/

 // init nécessaire à cause du ? final et donc args peut être vide (mais $args sera non null)
args returns [ String code, int size] @init{ $code = new String(); $size = 0; }
    : ( expression
    {
        // code java pour première expression pour arg
    }
    ( ',' expression
    {
        // code java pour expression suivante pour arg
    }
    )*
      )?
    ;


write returns [String code]
    : 'write' + '(' IDENTIFIANT ')'
    {
      AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

      $code = "PUSHG " + at.adresse + "\n" + "WRITE " + at.adresse + "\n";
    }
    ;

read returns [String code]
    : 'read' + '(' IDENTIFIANT ')'
    {
      AdresseType at = tablesSymboles.getAdresseType($IDENTIFIANT.text);

      {$code = "READ \n" + "STOREG " + at.adresse + "\n";}
    }
    ;

condition returns [String code]
    : 'true'  { $code = "PUSHI 1\n"; }
    | 'false' { $code = "PUSHI 0\n"; }

    | a=expression + '==' + b=expression
    {
      $code = $a.code + $b.code + "EQUAL" + "\n" +"JUMPF ";
    }

    | a=expression + '!=' + b=expression
    {
      $code = $a.code + $b.code + "NEQ" + "\n" + "JUMPF ";
    }

    | a=expression + '<>' + b=expression
    {
      $code = $a.code + $b.code + "NEQ" + "\n" + "JUMP";
    }

    | a=expression + '<' + b=expression
    {
      $code = $a.code + $b.code + "INF" + "\n" + "JUMPF ";
    }

    | a=expression + '>' + b=expression
    {
      $code = $a.code + $b.code + "SUP" + "\n" + "JUMPF ";
    }

    | a=expression + '<=' + b=expression
    {
      $code = $a.code + $b.code + "INFEQ" + "\n" + "JUMPF ";
    }

    | a=expression + '>=' + b=expression
    {
      $code = $a.code + $b.code + "SUPEQ" + "\n" + "JUMPF ";
    }
    ;

block returns [String code]
    : '{' + instruction + '}'
    {
      $code = $instruction.code;
    }
    ;

while_loop returns [String code]
    : 'while' + '(' + condition + ')' + block
    {
      String next = getNewLabel();

      String label = getNewLabel();

      $code = $condition.code + "JUMPF " + next + "\n" + "LABEL " + label + "\n" + $block.code + "CALL " + label + "\n" + "LABEL " + next + "\n";
    }
    ;

operateursLogiques returns [String code]
    : a=condition + '||' + b=condition
    {
      $code = "PUSHI 0";
    }
    | '!' + condition
    {
      $code = "PUSHI 0 \n" + $condition.code + "SUPEQ \n";
    }
    ;

si returns [String code]
    : 'if' + '(' + condition + ')' + a=block + 'else' + b=block
    {
      String next = getNewLabel();

      $code = $condition.code + next + "\n" + $a.code + "LABEL " + next + "\n" + $b.code;
    }
    | 'if' + '(' + condition + ')' + block
    {
      String next = getNewLabel();

      $code = $condition.code + next + "\n" + $block.code + "LABEL " + next + "\n";
    }
    ;

forLoop returns [String code]
    : 'for' + '(' + a=assignation + ';' + condition + ';' b=assignation + ')' + block
    {
      String label = getNewLabel();

      String next = getNewLabel();

      $code = $a.code + $condition.code + next + "\n" + $b.code + "LABEL " + label + "\n" + $block.code + "CALL " + label + "\n" + next + "\n";
    }
    ;

repeat returns [String code]
    : 'repeat' + block + 'until' + '(' + condition + ')'
    {
      System.out.println("hey");

      String label = getNewLabel();

      String next = getNewLabel();

      $code = "LABEL " + label + "\n" + $block.code + $condition.code + next + "\n" + "CALL " + label + "\n" + next + "\n";
    }
    ;

finInstruction : ( NEWLINE | ';' )+ ;

// lexer
NEWLINE : '\r'? '\n';

TYPE : 'int' | 'double';

WS :   (' '|'\t')+ -> skip;

BOOLEAN : 'true' | 'false';

MOTCLEIDENTIFIANT
    : 'var' | ':' | ';' | '(' | ')' | '{' | '}' | 'write' | 'read'| 'while' | 'for' | 'repeat' | 'until' | 'if' | 'else'
    ;

OPERATEURS
  : '||' | '&&' | '!' | '=' | '==' | '!=' | '<>' | '<' | '>' | '<=' | '>=' | '+='
  ;

IDENTIFIANT
    :   ('a'..'z' | 'A'..'Z' | '_')('a'..'z' | 'A'..'Z' | '_' | '0'..'9')*
    ;

ENTIER : ('0'..'9')+ ;

FLOTTANT : (ENTIER+'.'ENTIER+) ;

COMMENT: '/*' ('/'*? COMMENT | ('/'* | '*'*) ~[/*])*? '*'*? '*/' -> skip;

UNMATCH : . -> skip ;
