with Courbes.Visiteurs; use Courbes.Visiteurs;

package body Courbes.Singletons is
    function Ctor_Singleton (P : Point2D) return Singleton is
    begin
        return (Debut => P, Fin => P);
    end;

    -- X pas utilisé
    overriding function Obtenir_Point(Self : Singleton; X : Coordonnee_Normalisee) return Point2D is
    begin 
        return Self.Debut;
    end;

    overriding procedure Accepter (Self : Singleton; Visiteur : Visiteur_Courbe'Class) is
    begin
        Visiteur.Visiter (Self);
    end;
end Courbes.Singletons;
