with Ada.Text_IO, Ada.Float_Text_IO, Ada.Characters.Handling, Ada.Strings, Ada.Strings.Fixed, Ada.Strings.Unbounded;
use Ada.Text_IO, Ada.Float_Text_IO, Ada.Characters.Handling, Ada.Strings, Ada.Strings.Fixed, Ada.Strings.Unbounded;

package body Parser_Svg is
    function Get_Ligne_D(
        Nom_Fichier : String)
        return String
    is
        Ligne_D : Unbounded_String := Null_Unbounded_String;
        Fichier : Ada.Text_IO.File_Type;
    begin
        -- On ouvre le fichier
        Ada.Text_IO.Open (Fichier, Ada.Text_IO.In_File, Nom_Fichier);

        -- On s'arrête qd la ligne est trouvée ou à la fin du fichier
        while Length(Ligne_D) = 0
            and then not Ada.Text_IO.End_Of_File (Fichier) loop
            declare
                -- On obtient une ligne, et on enlève les espaces en début/fin
                Ligne : String := Trim (Ada.Text_IO.Get_Line (Fichier), Both);
            begin
                -- on récupère la ligne commençant par "d="
                if Ligne'Length >= Marqueur_Ligne'Length and then Ligne (Marqueur_Ligne'Range) = Marqueur_Ligne then
                    Ligne_D := To_Unbounded_String (Ligne (Ligne'First + Marqueur_Ligne'Length .. Ligne'Last - 1));
                end if;
            end;
        end loop;

        -- Fermeture du fichier
        Ada.Text_IO.Close (Fichier);

        -- Si on a pas trouvé de ligne 
        if Length(Ligne_D) = 0 then
            raise Courbe_Abs;
        end if;

        return To_String (Ligne_D);
    end;

    procedure Move_To(Point : Point2D; L : in out Liste) is
    begin
        null;
    end;

    procedure Line_To(Point : Point2D; L : in out Liste) is
    begin
        null;
    end;

    procedure Horizontal_Line_To(X : Float; L : in out Liste) is
    begin
        null;
    end;

    procedure Vertical_Line_To(Y : Float; L : in out Liste) is
    begin
        null;
    end;

    procedure Curve_To(P1, C1, C2, P2 : Point2D; L : in out Liste) is
    begin
        null;
    end;

    procedure Quadratic_Curve_To(P1, C, P2 : Point2D; L : in out Liste) is
    begin
        null;
    end;

    -- Requiert Position = 1 ou Ligne_D (Position) = Separateur
    function Voir_Au_Separateur(
        Ligne_D : String;
        Position : in Integer;
        Fin_Position : out Integer)
        return String
    is
        Contenu_Deb, Contenu_Fin : Integer := Ligne_D'First;
    begin
        Fin_Position := Position + 1;

        -- On vérifie que le car. courant est bien un séparateur
        -- On est supposé traiter la chaine de séparateur en séparateur
        -- Cas particulier: quand position = début, on ignore ce test
        if Position /= Ligne_D'First
            and then Ligne_D (Position) /= Separateur
        then
            raise Courbe_Illisible with "Mauvais positionnement (courant /= séparateur)";
        end if;

        -- On avance jusqu'à trouver le prochain séparateur
        -- ou jusqu'à la fin de la chaine
        while Fin_Position <= Ligne_D'Last
            and then Ligne_D (Fin_Position) /= Separateur loop
            Fin_Position := Fin_Position + 1;
        end loop;

        Contenu_Deb := Position;
        Contenu_Fin := Fin_Position;

        -- Si on n'est pas à la fin de la chaîne
        -- alors la fin du contenu est
        -- 1 car. avant le séparateur suivant
        if Fin_Position /= Ligne_D'Last then
            Contenu_Fin := Contenu_Fin - 1;
        end if;

        -- Si on n'est pas au début de la chaîne
        -- alors le début du contenu est
        -- 1 car. après le séparateur précedent
        if Position /= Ligne_D'First then
            Contenu_Deb := Contenu_Deb + 1;
        end if;

        return Ligne_D (Contenu_Deb .. Contenu_Fin);
    end;

    -- Avance jusqu'au prochain séparateur et récupère le contenu
    -- Requiert Position = 1 ou Ligne_D (Position) = Separateur
    function Avancer_Au_Separateur(
        Ligne_D : String;
        Position : in out Integer)
        return String
    is
        Fin_Position : Integer;
    begin
        declare
            Contenu : String := Voir_Au_Separateur (Ligne_D, Position, Fin_Position);
        begin
            Position := Position + Fin_Position;

            return Contenu;
        end;
    end;

    procedure Lire_Point2D(
        Ligne_D : String;
        Position : in out Integer;
        Point : in out Point2D)
    is
        Contenu : String := Avancer_Au_Separateur(Ligne_D,  Position);

        X, Y : Float;
    begin

        -- On cherche la position du
        -- séparateur d'un jeu de coordonnées
        declare
            Separateur_Position : Positive := Contenu'First;
        begin
            -- On cherche le séparateur
            -- On s'arrête si on est à la fin de la chaine
            -- ou si on trouve le séparateur
            while Separateur_Position <= Contenu'Last
                and then Contenu (Separateur_Position) /= Separateur_Coord loop
                -- On avance
                Separateur_Position := Separateur_Position + 1;
            end loop;

            -- Le séparateur est à la fin ou au début
            -- il n'y a rien après
            -- et il manque une information
            if Separateur_Position = Contenu'Last 
                or else Separateur_Position = Contenu'First then
                raise Courbe_Illisible with "Manque deuxième coordonnée";
            end if;

            declare
                -- On récupère la première coordonnée
                X_Text : String := Contenu (Contenu'First .. Separateur_Position - 1);
                -- On récupère la deuxième coordonnée
                Y_Text : String := Contenu (Separateur_Position + 1 .. Contenu'Last);
            begin
                -- Conversion en flottant
                X := Float'Value (X_Text);
                Y := Float'Value (Y_Text);
            exception
                when Constraint_Error =>
                    -- Si les nombres sont mal formés...
                    raise Courbe_Illisible with "Nombre flottant mal formé";
            end;
        end;

        Point := (1 => Point(1) + X, 2 => Point(2) + Y);        
    end;

    function Lire_Coord(
        Ligne_D : String;
        Position : in out Integer)
        return Float
    is
        Contenu : String := Avancer_Au_Separateur(Ligne_D, Position);
    begin
        -- On transforme le contenu en flottant
        return Float'Value (Contenu);
    exception
        when Constraint_Error =>
            -- Si les nombres sont mal formés...
            raise Courbe_Illisible with "Flottant mal formé";
    end;

    procedure Lire_OpCode (
        Ligne_D : String;
        Position : in out Integer;
        Op_Abs : out Op_Code_Absolute;
        Relatif_Vers_Absolu : out Boolean)
    is
        Contenu : String := Avancer_Au_Separateur(Ligne_D, Position);
        Op : Op_Code;
    begin
        -- On avance au séparateur

        if Contenu'Length /= 1 then
            -- L'opcode est composé d'une seule lettre
            raise Courbe_Illisible with "Instruction SVG mal formée (longeur > 1): " & Contenu;
        end if;

        declare
            Last : Positive;

            -- https://www2.adacore.com/gap-static/GNAT_Book/html/aarm/AA-A-10-10.html
            package Op_Code_IO is new Enumeration_IO (Op_Code);
        begin
            -- On convertit la chaine en opcode
            -- On ajoute des quotes pour que le parser sache
            -- que c'est un enum caractère
            Op_Code_IO.Get("'" & Contenu & "'", Op, Last);
        exception
            when Data_Error =>
                -- Si opcode non supporté
                raise Courbe_Illisible with "Instruction SVG non supportée: " & Contenu & " " & Positive'Image(Contenu'Length);
        end;

        -- Si l'opcode est en minuscule (coord. relatives)
        -- On indique travailler en relatif
        Relatif_Vers_Absolu := Op in Op_Code_Relative;

        -- Et on le convertit en majuscule (coord. absolues)
        Op_Abs := Op_Code'Value(To_Upper (Op_Code'Image(Op)));
    end;

    function Point_Relatif (
        Point_Base : Point2D;
        Relatif_Vers_Absolu : Boolean)
        return Point2D
    is
    begin
        if Relatif_Vers_Absolu then
            return Point_Base;
        else
            return (others => 0.0);
        end if;
    end;
    
    procedure Gerer_OpCode (
        Ligne_D : String;
        Position : in out Integer;
        Op : Op_Code_Absolute;
        L : in out Liste;
        Relatif_Vers_Absolu : Boolean)
    is
        Point_Base : Point2D := (others => 0.0);
    begin
        Put_Line ("Gestion opcode" & Op_Code'Image(Op));
        if Relatif_Vers_Absolu and then Taille (L) /= 0  then
            Point_Base := Queue (L);
        end if;

        case Op is
            when 'M' =>
                declare
                    P : Point2D;
                begin
                    Lire_Point2D(Ligne_D, Position, P);
                    P := P + Point_Base;

                    Move_To(P, L);
                end;
            when 'L' =>
                declare
                    P : Point2D;
                begin
                    Lire_Point2D(Ligne_D, Position, P);
                    P := P + Point_Base;

                    Line_To(P, L);
                end;
            when 'H' =>
                declare
                    X : Float := Lire_Coord(Ligne_D, Position) + Point_Base (1);
                begin
                    Horizontal_Line_To(X, L);
                end;
            when 'V' =>
                declare
                    Y : Float := Lire_Coord(Ligne_D, Position) + Point_Base (2);
                begin
                    Horizontal_Line_To(Y, L);
                end;
            when 'C' => 
                declare
                    P1, C1, C2, P2 : Point2D;
                begin
                    Lire_Point2D(Ligne_D, Position, P1);
                    Lire_Point2D(Ligne_D, Position, C1);
                    Lire_Point2D(Ligne_D, Position, C2);
                    Lire_Point2D(Ligne_D, Position, P2);

                    P1 := P1 + Point_Base;
                    C1 := C1 + Point_Base;
                    C2 := C2 + Point_Base;
                    P2 := P2 + Point_Base;

                    Curve_To(P1, C1, C2, P2, L);    
                end;
            when 'Q' =>
                declare
                    P1, C, P2 : Point2D;
                begin
                    Lire_Point2D(Ligne_D, Position, P1);
                    Lire_Point2D(Ligne_D, Position, C);
                    Lire_Point2D(Ligne_D, Position, P2);

                    P1 := P1 + Point_Base;
                    C := C + Point_Base;
                    P2 := P2 + Point_Base;

                    Quadratic_Curve_To(P1, C, P2, L);
                end;
        end case;
    end;

    procedure Chargement_Bezier(Nom_Fichier : String; L : out Liste) is
        -- on charge le fichier svg
        Ligne_D : String := Get_Ligne_D(Nom_Fichier);

        Position : Integer := Ligne_D'First;

        Op_Abs : Op_Code_Absolute;
        Relatif_Vers_Absolu : Boolean;
    begin
        -- analyse de cette même ligne en gérant
        -- les différents opcode (mlhvcq et MLHVCQ)

        -- Tant qu'on est pas à la fin de la ligne
        while Position <= Ligne_D'Last loop
            -- Lecture de l'opcode L,
            Lire_OpCode (Ligne_D, Position, Op_Abs, Relatif_Vers_Absolu);

            -- Traitement de l'opcode
            Gerer_OpCode (Ligne_D, Position, Op_Abs, L, Relatif_Vers_Absolu);
        end loop;
    end;
end;
