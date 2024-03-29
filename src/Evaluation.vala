/*-
 * Copyright (C) 2023 Fyra Labs
 *
 * The following code uses parts of the original work,
 * while keeping the original attribution.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

using GLib.Math;

namespace Abacus.Core {
    private errordomain EVAL_ERROR {
        NO_OPERATOR,
        DIVIDE_BY_ZERO_ERROR
    }

    private errordomain SHUNTING_ERROR {
        DUMMY,
        NO_OPERATOR,
        UNKNOWN_TOKEN,
        STACK_EMPTY
    }

    public errordomain OUT_ERROR {
        EVAL_ERROR,
        CHECK_ERROR,
        SHUNTING_ERROR,
        SCANNER_ERROR
    }

    public class Evaluation : Object {

        [CCode (has_target = false)]
        private delegate double Eval (double a = 0, double b = 0);

        private struct Operator { string symbol; int inputs; int prec; string fixity; Eval eval; }
        static Operator[] operators = {
            Operator () { symbol = "+", inputs = 2, prec = 1, fixity = "LEFT", eval = (a, b) => a + b },
            Operator () { symbol = "-", inputs = 2, prec = 1, fixity = "LEFT", eval = (a, b) => a - b },
            Operator () { symbol = "−", inputs = 2, prec = 1, fixity = "LEFT", eval = (a, b) => a - b },
            Operator () { symbol = "*", inputs = 2, prec = 2, fixity = "LEFT", eval = (a, b) => a * b },
            Operator () { symbol = "×", inputs = 2, prec = 2, fixity = "LEFT", eval = (a, b) => a * b },
            Operator () { symbol = "/", inputs = 2, prec = 2, fixity = "LEFT", eval = (a, b) => a / b },
            Operator () { symbol = "÷", inputs = 2, prec = 2, fixity = "LEFT", eval = (a, b) => a / b },
            Operator () { symbol = "%", inputs = 1, prec = 5, fixity = "LEFT", eval = (a, b) => b / 100.0 }
        };

        public Scanner scanner = new Scanner ();

        public Evaluation () {}

        public string evaluate (string str, int d_places) throws OUT_ERROR {
            try {
                var tokenlist = scanner.scan (str);
                var d = 0.0;
                try {
                    tokenlist = shunting_yard (tokenlist);
                    try {
                        d = eval_postfix (tokenlist);
                    } catch (Error e) {
                        throw new OUT_ERROR.EVAL_ERROR (e.message);
                    }
                } catch (Error e) {
                    throw new OUT_ERROR.SHUNTING_ERROR (e.message);
                }
                return number_to_string (d, d_places);
            } catch (Error e) {
                throw new OUT_ERROR.SCANNER_ERROR (e.message);
            }
        }

        /* Djikstra's Shunting Yard algorithm for ordering a tokenized list into Reverse Polish Notation */
        private List<Token> shunting_yard (List<Token> token_list) throws SHUNTING_ERROR {
            List<Token> output = new List<Token> ();
            Queue<Token> op_stack = new Queue<Token> ();

            foreach (Token t in token_list) {
                switch (t.token_type) {
                case TokenType.NUMBER:
                    output.append (t);
                    break;
                case TokenType.SEPARATOR:
                    while (!op_stack.is_empty ()) {
                        output.append (op_stack.pop_tail ());
                    }
                    break;
                case TokenType.OPERATOR:
                    if (!op_stack.is_empty ()) {
                        Operator op1 = get_operator (t);
                        Operator op2 = Operator ();

                        try {
                            op2 = get_operator (op_stack.peek_tail ());
                        } catch (SHUNTING_ERROR e) {}

                        while (!op_stack.is_empty () && op_stack.peek_tail ().token_type == TokenType.OPERATOR &&
                               ((op2.fixity == "LEFT" && op1.prec <= op2.prec) ||
                                (op2.fixity == "RIGHT" && op1.prec < op2.prec))) {

                            output.append (op_stack.pop_tail ());

                            if (!op_stack.is_empty ()) {
                                try {
                                    op2 = get_operator (op_stack.peek_tail ());
                                } catch (SHUNTING_ERROR e) {}
                            }
                        }
                    }
                    op_stack.push_tail (t);
                    break;
                default:
                    throw new SHUNTING_ERROR.UNKNOWN_TOKEN ("'%s' is unknown.", t.content);
                }
            }

            while (!op_stack.is_empty ()) {
                output.append (op_stack.pop_tail ());
            }

            return output;
        }

        private double eval_postfix (List<Token> token_list) throws EVAL_ERROR {
            Queue<Token> stack = new Queue<Token> ();

            foreach (Token t in token_list) {
                if (t.token_type == TokenType.NUMBER) {
                    stack.push_tail (t);
                } else if (t.token_type == TokenType.OPERATOR) {
                    try {
                        Operator o = get_operator (t);
                        Token t1 = stack.pop_tail ();
                        Token t2 = new Token ("0", TokenType.NUMBER);

                        if (!stack.is_empty () && o.inputs == 2) {
                            t2 = stack.pop_tail ();
                        }
                        if (o.symbol == "/" && t1.content == "0" || o.symbol == "÷" && t1.content == "0") {
                            throw new EVAL_ERROR.DIVIDE_BY_ZERO_ERROR ("Division by zero.");
                        } else {
                            stack.push_tail (compute (o.eval, t2, t1));
                        }
                    } catch (SHUNTING_ERROR e) {
                        throw new EVAL_ERROR.NO_OPERATOR ("Found no operators.");
                    }
                }
            }
            return double.parse (stack.pop_tail ().content);
        }

        /* Checks for real TokenType (which are TokenType.ALPHA at the moment) */
        public static bool is_operator (Token t) {
            foreach (Operator o in operators) {
                if (t.content == o.symbol) {
                    return true;
                }
            }
            return false;
        }

        private Operator get_operator (Token t) throws SHUNTING_ERROR {
            foreach (Operator o in operators) {
                if (t.content == o.symbol) {
                    return o;
                }
            }
            throw new SHUNTING_ERROR.NO_OPERATOR ("");
        }

        private Token compute (Eval eval, Token t1, Token t2) throws EVAL_ERROR {
            double d = eval (double.parse (t1.content), double.parse (t2.content));
            if (fabs (d) - 0.0 < double.EPSILON) {
                d = 0.0;
            }
            return new Token (d.to_string (), TokenType.NUMBER);
        }

        private string number_to_string (double d, int d_places) {
            string s = ("%.9f".printf (d));
            string s_localized = s.replace (".", scanner.decimal_symbol);

            /* Remove trailing 0s or decimal symbol */
            while (s_localized.has_suffix ("0")) {
                s_localized = s_localized.slice (0, -1);
            }
            if (s_localized.has_suffix (scanner.decimal_symbol)) {
                s_localized = s_localized.slice (0, -1);
            }

            /* Insert separator symbol in large numbers */
            var builder = new StringBuilder (s_localized);
            var decimal_pos = s_localized.last_index_of (scanner.decimal_symbol);
            if (decimal_pos == -1) {
                decimal_pos = s_localized.length;
            }

            int end_position = 0;
            if (s_localized.has_prefix ("-")) {
                end_position = 1;
            }
            for (int i = decimal_pos - 3; i > end_position; i -= 3) {
                builder.insert (i, scanner.separator_symbol);
            }
            return builder.str;
        }
    }
}