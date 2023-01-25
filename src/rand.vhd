--***************************************************************************
--**                                                                       **
--**        Montecarlo  (erzeugung von pseudo Zufallszahlen)               **
--**                                                                       **
--**-----------------------------------------------------------------------**
--** Datei:        RAND.VHD                                                **
--** Autor:        Ulrich Becker                                           **
--** Datum:        10.02.1998                                              **
--** Aenderung:    10.02.1998                                              **
--***************************************************************************

package Montecarlo is

   type LONG is range -2147483647 to 2147483647;

   procedure Monte( Z: inout integer; S16, S26, S36: inout integer );
   function intDiv( Divident, Divisor: LONG ) return LONG; 
   
end Montecarlo;

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
package body Montecarlo is

-- Empfohlene Startwerte: S16 := 12, S26 := 23: S36 := 24;
-----------------------------------------------------------------------------
procedure Monte( Z: inout integer; S16, S26, S36: inout integer ) is
   variable K: integer;    
begin
   K := S16 / 206;
   S16 := 157 * (S16 - K * 217) - K * 21;
   if S16 < 0 then
      S16 := S16 + 32263;
   end if;
   K := S26 / 217;
   S26 := 146 * (S26 - K * 217) - K * 45;
   if S26 < 0 then
      S26 := S26 + 31727;
   end if;
   K := S36 / 222;
   S36 := 142 * (S36 - K * 222) - K * 133;
   if S36 < 0 then
      S36 := S36 + 31657;
   end if;
   Z := S16 - S26;
   if Z > 706 then
      Z := Z - 32362;
   end if;
   Z := Z + S36;
   if Z < 0 then
      Z := Z + 32632;
   end if;  
end Monte;

-----------------------------------------------------------------------------
function intDiv( Divident, Divisor: LONG ) return LONG is
   variable ret: LONG;
begin
   assert Divisor /= 0 report "Division durch null !";
   ret := Divident / Divisor;
   if (Divident mod Divisor) >= (Divisor / 2) then
      ret := ret + 1;
   end if;
   return ret;  
end intDiv;


-----------------------------------------------------------------------------
end Montecarlo;
