--***************************************************************************
--**                                                                       **              
--**            Testbench fuer Manchester Encoder/Decoder                  **
--**                                                                       **
--**-----------------------------------------------------------------------**
--** Datei:          man1_tb.vhd                                           **
--** Pruefling:      man1.vhd                                              **
--** Autor:          Ulrich Becker                                         **
--** Datum:          16.12.1997                                            **
--** Update:         23.03.1998                                            **
--***************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;

use work.Montecarlo.all;

entity MAN_II_TB is
end MAN_II_TB;

-----------------------------------------------------------------------------
architecture MAN_II_TB_ARCH of MAN_II_TB is
   component MAN_SOC
      port( RST:       in     bit;
            CLK:       in     bit;
            SYS_CLK:   buffer bit;
            R_T:       in     bit;
            TD:        buffer bit;
            RD:        in     bit;
            D_OUT:     in     bit;
            D_IN:      buffer bit;
            D_CLK:     in     bit;
            READY:     buffer bit;
            CR_DETECT: in     bit;
            IRQ:       inout  std_logic;
            OVERFLOW:  buffer bit;
            VALID:     in     bit;
            BUSY:      buffer bit;
            CR_BUSY:   buffer bit;
            C_D_IN:    buffer bit;
            C_D_OUT:   in     bit;
            E_TIME:    buffer bit;
            E_PARITY:  buffer bit;
            ERR:       buffer bit            
         );
   end component;
   
   constant n: integer := 16;
   --signal RST1:       bit := '0';
   signal CLK1:       bit := '0';
   signal SYS_CLK1:   bit;
   signal R_T1:       bit := '0';
   signal TD1:        bit := '0';
   signal RD1:        bit := '0';
   signal D_OUT1:     bit := '0';
   signal D_IN1:      bit := '0';
   signal D_CLK1:     bit := '0';
   signal READY1:     bit := '0';
   signal CR_DETECT1: bit := '1';
   signal IRQ1:       std_logic;
   signal OVERFLOW1:  bit := '0';
   signal VALID1:     bit := '0';
   signal BUSY1:      bit := '0';
   signal CR_BUSY1:   bit;
   signal C_D_IN1:    bit := '0';
   signal C_D_OUT1:   bit := '1';
   signal E_TIME1:    bit := '0';
   signal E_PARITY1:  bit := '0';   
   signal ERR1:       bit := '0';
   
   --signal RST2:       bit := '0';
   signal CLK2:       bit := '0';
   signal R_T2:       bit := '0';
   signal TD2:        bit := '0';
   signal RD2:        bit := '0';
   signal D_OUT2:     bit := '0';
   signal D_IN2:      bit := '0';
   signal D_CLK2:     bit := '0';
   signal READY2:     bit := '0';
   signal CR_DETECT2: bit := '1';
   signal IRQ2:       std_logic;
   signal OVERFLOW2:  bit := '0';
   signal VALID2:     bit := '0';
   signal BUSY2:      bit := '0';
   signal CR_BUSY2:   bit;
   signal C_D_IN2:    bit := '0';
   signal C_D_OUT2:   bit := '0';
   signal E_TIME2:    bit := '0';
   signal E_PARITY2:  bit := '0';   
   signal ERR2:       bit := '0';
   
   signal in_reg:     bit_vector( 15 downto 0 );
   signal RST:        bit := '0';        -- Master- Reset (global)
   signal B_CLK:      bit := '0';        -- Bit- Uebertragungstakt
   signal T:          bit := '0';        -- Takt fuer Ein- und Auslesealgorithmus
   signal W:          bit := '1';        -- Unterbrechung der Strecke bei 0
   signal TD1x:       bit;               -- gestoertes TD1- Signal
   signal Z:          integer := 0;      -- Zufallswert
   
   type StoerTyp is ( OK, Rausch, invers, Flanke, HIGH, LOW );
   signal Stoer:      StoerTyp := OK;
      
   constant BadenBaden: integer := 100;   -- Wertebereich fuer Zufallsgenerator
   signal Rauschgrenze: integer :=  50;   -- Schwellenwert fuer Signalaenderung Rauscher
   signal Rauscher:     Bit     := '0';   -- kaotisches Signal
   signal level:        integer :=  10;   -- Schaltwarscheinlichkeit fuer Bit- Inverter in %;
   signal BitInverter:  Bit     := '0';   -- Invertierungsflag
   
      
   constant Dauer:    bit_vector( 3 downto 0 ) := "0001";
   constant DauerI:   bit_vector( 3 downto 0 ) := "0000";
   constant ID:       bit_vector( 5 downto 0 ) := "111101";
   constant IDI:      bit_vector( 3 downto 0 ) := "0001"; 

begin
-----------------------------------------------------------------------------
   man_1 : MAN_SOC
   port map( RST       =>   RST,     
             CLK       =>   CLK1,
             SYS_CLK   =>   SYS_CLK1,     
             R_T       =>   R_T1,    
             TD        =>   TD1,      
             RD        =>   RD1,      
             D_OUT     =>   D_OUT1,   
             D_IN      =>   D_IN1,    
             D_CLK     =>   D_CLK1,
             READY     =>   READY1,
             CR_DETECT =>   CR_DETECT1,
             IRQ       =>   IRQ1, 
             OVERFLOW  =>   OVERFLOW1,
             VALID     =>   VALID1,
             BUSY      =>   BUSY1,
             CR_BUSY   =>   CR_BUSY1,   
             C_D_IN    =>   C_D_IN1,  
             C_D_OUT   =>   C_D_OUT1,
             E_TIME    =>   E_TIME1,  
             E_PARITY  =>   E_PARITY1,
             ERR       =>   ERR1   
           );
           
   man2 : MAN_SOC
   port map( RST       =>   RST,     
             CLK       =>   CLK2,
             SYS_CLK   =>   open,     
             R_T       =>   R_T2,    
             TD        =>   TD2,      
             RD        =>   RD2,      
             D_OUT     =>   D_OUT2,   
             D_IN      =>   D_IN2,    
             D_CLK     =>   D_CLK2,
             READY     =>   READY2,
             CR_DETECT =>   CR_DETECT2,   
             IRQ       =>   IRQ2,
             OVERFLOW  =>   OVERFLOW2,
             VALID     =>   VALID2,
             BUSY      =>   BUSY2,   
             CR_BUSY   =>   CR_BUSY2,
             C_D_IN    =>   C_D_IN2,  
             C_D_OUT   =>   C_D_OUT2,
             E_TIME    =>   E_TIME2,  
             E_PARITY  =>   E_PARITY2, 
             ERR       =>   ERR2   
           );

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --   
   pullup_irq1: process( IRQ1 )
   begin
      IRQ1 <= 'H';
   end process;

   pullup_irq2: process( IRQ2 )
   begin
      IRQ2 <= 'H';
   end process;
           
   oszi1: process( CLK1 )
   begin
      CLK1 <= not CLK1 after 100 ns;
   end process;
   
   oszi2: process( T )
   begin
      T <= not T after 50 ns;
   end process;
   
   oszi3: process( CLK2 )
   begin
      CLK2 <= not CLK2 after 100 ns;
   end process;
--  --  --  --  --  --  --  --  Uebertragungsstrecke --  --  --  --  --  --  --   
   Strecke: process( TD1x, TD2, W )
   begin
      RD1 <= TD2 and W;
      RD2 <= TD1x and W;
   end process;
   
--  --  --  --  --  --  --  --  -- Montecarlo --  --  --  --  --  --  --  --  -- 
-- Prozess erzeugt eine Zufallszahl   
   Montecarlo: process( SYS_CLK1 )
      variable a: integer := 12;
      variable b: integer := 23;
      variable c: integer := 24;
      variable m: integer;
   begin
      if SYS_CLK1'event and SYS_CLK1 = '0' then
         Monte( m, a, b, c );
         m := m mod BadenBaden;
         if m >= ((BadenBaden + Rauschgrenze) / 2 ) then
            Rauscher <= '1';
         elsif m <= ((BadenBaden - Rauschgrenze) / 2 ) then
            Rauscher <= '0';
         end if;            
         Z <= m;
      end if;
   end process;

   Wiesbaden: process( B_CLK, Z )
   begin
      if B_CLK'event and B_CLK = '1' then
         if (Z mod (BadenBaden - level)) = 0 then
            BitInverter <= '1';
         else
            BitInverter <= '0';
         end if;
      end if;
   end process;

   
--  --  --  --  --  --  --  Stoereinfluesse --  --  --  --  --  --  --  --  --
   Stoerung: process( B_CLK, Stoer, TD1, Rauscher, BitInverter  )
   begin
       case Stoer is
          when OK =>
             TD1x <= TD1;
         
          when Rausch =>
             Td1x <= Rauscher;
          
          when invers => 
             Td1x <= TD1 xor BitInverter;
          
          when Flanke =>
             Td1x <= TD1 or BitInverter;
             
          when HIGH =>
             Td1x <= '1';
             
          when LOW =>
             Td1x <= '0';   
          
       end case;
   end process;
   
   
--  --  --  --  --  --  --  BitTakt --  --  --  --  --  --  --  --  --  --  --
--Prozess erzeugt den Uebertragungstakt
   BitTakt: process( SYS_CLK1 )
      Variable n: integer := 4;
   begin
      if SYS_ClK1'event and SYS_CLK1 = '1' then
         n := n + 1;
         if n = 8 then
            n := 0;
            B_CLK <= not B_CLK;
         end if;
      end if;
   end process;
      
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --     
data_out: process( T, RST )
   variable S: integer := 0;
   variable P: integer := 0;
   variable d1: bit_vector( 15 downto 0 ) := b"1111_0101_0000_1010";
   variable d2: bit_vector( 15 downto 0 ) := b"0101_0101_0101_0101";
begin
   if RST = '1' then
      S := 0;
      P := 0; 
   elsif T'event and T = '1' then
      case S is
      
         when 0 => 
            if P < 4 then
               S := S;
               D_OUT1 <= Dauer(P);
               D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               S := 2;
               P := 0;
            end if;
            
         when 2 =>
            if P < 4 then
               S := S;
               D_OUT1 <= DauerI(P);
               D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               S := 3;
               P := 0;
            end if;
            
         when 3 =>
            VALID1 <= '1';
            D_OUT1 <= '0';
            D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
            S := 4;

         when 4 =>
            VALID1 <= '0';
            S := 5;
            
         when 5 =>
            if P < 6 then
               S := S;
               D_OUT1 <= ID(P);
               D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               S := 7;
               p := 0;
            end if;
            
         when 7 =>
            if P < 4 then
               S := S;
               D_OUT1 <= IDI(P);
               D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               P := 0;
               S := 8;
            end if;
            
         when 8 =>
            VALID1 <= '1';
            D_OUT1 <= '0';
            D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
            S := 9;
            
         when 9 =>
            VALID1 <= '0';
            S := 10;                        
      
 --     
         when 10 =>
            if READY1 = '0' THEN
               if P < 16 then
                  D_OUT1 <= d1(P);
                  P := P + 1;
                  S := S;
                  D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
               else
                  S := 11;
               end if;
            else
               S := S;
            end if;
        
         when 11 =>
            P := 0;
            VALID1 <= '1';
            D_OUT1 <= '1';
            D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
            S := 12;
         
         when 12 =>
            VALID1 <= '0';
            if READY1 = '1' then
               S := 13;
            else
               S := 11;
            end if;
            
         when 13 =>
            if READY1 = '0' THEN
               if P < 16 then
                  D_OUT1 <= d2(P);
                  P := P + 1;
                  S := S;
                  D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
               else
                  S := 14;
               end if;
            else
               S := S;
            end if;
            
         when 14 =>
            P := 0;
            VALID1 <= '1';
            D_OUT1 <= '1';
            D_CLK1 <= '1' after 2 ns, '0' after 4 ns;
            S := 15;
         
         when 15 =>
            VALID1 <= '0';
            if READY1 = '1' then
               S := 16;
            else
               S := 14;
            end if;
            
         when others =>
           P := 0;
           S := 10;
           
      end case;
   end if;
end process;

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  - 
data_in: process( T, RST )
   variable S: integer := 0;
   variable P: integer := 0;
begin
   if RST = '1' then
      S := 0;
      P := 0;
   elsif T'event and T = '1' then
      case S is

         when 0 => 
            if P < 4 then
               S := S;
               D_OUT2 <= Dauer(P);
               D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               S := 2;
               P := 0;
            end if;
            
         when 2 =>
            if P < 4 then
               S := S;
               D_OUT2 <= DauerI(P);
               D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               S := 3;
               P := 0;
            end if;
            
         when 3 =>
            VALID2 <= '1';
            D_OUT2 <= '0';
            D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
            S := 4;

         when 4 =>
            VALID2 <= '0';
            S := 5;
            
         when 5 =>
            if P < 6 then
               S := S;
               D_OUT2 <= ID(P);
               D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               S := 7;
               p := 0;
            end if;
            
         when 7 =>
            if P < 4 then
               S := S;
               D_OUT2 <= IDI(P);
               D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
               P := P + 1;
            else
               P := 0;
               S := 8;
            end if;
            
         when 8 =>
            VALID2 <= '1';
            D_OUT2 <= '0';
            D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
            S := 9;
            
         when 9 =>
            VALID2 <= '0';
            S := 10;
            R_T2 <= '1';                        

--      
         when 10 =>
            if ERR2 = '1' then
                assert OVERFLOW2 = '0' report "Ueberlauffehler !!!";
                assert E_TIME2 = '0'   report "Flankenfehler !!!";
                assert E_PARITY2 = '0' report "Paritaetsfehler !!!";
                D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
            end if;
            if READY2 = '1' then                                          
               S := 11;
               P := 0;
            else 
               S := S;
            end if;
            
         when 11 =>
            in_reg(P) <= D_IN2;
            P := P + 1;
            S := 12;
            
         when 12 =>
            D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
            if P > 15 then
               S := 13;
            else 
               S := 11;
            end if;
            
         when 13 =>
            VALID2 <= '1';
            D_OUT2 <= '1';
            S := 14;
            
         when 14 =>
            D_CLK2 <= '1' after 2 ns, '0' after 4 ns;
            S := 15;
            
         when 15 =>
            VALID2 <= '0';
            S := 10;  
      
      
         when others =>
            P := 0;
            S := 10;
            
      end case;
   end if;

end process;

end MAN_II_TB_ARCH;


-----------------------------------------------------------------------------
configuration MAN_II_TB_CFG of MAN_II_TB is

   for MAN_II_TB_ARCH
      for all: MAN_SOC
         use configuration work.MAN_II_CFG;
      end for;
   end for;

end MAN_II_TB_CFG;
           

