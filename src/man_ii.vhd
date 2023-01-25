--***************************************************************************
--**                                                                       **              
--**     Manchester Encoder/Decoder  (Experimentierbaustein)               **
--**                                                                       **
--**-----------------------------------------------------------------------**
--** Datei:          MAN_II.VHD                                            **
--** Testbanch:      MAN1_TB.VHD                                           **
--** Autor:          Ulrich Becker                                         **
--** Datum:          16.12.1997                                            **
--** Update:         31.03.1998                                            **
--***************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;

-----------------------------------------------------------------------------
entity MAN_II is

   port( RST:       in     bit;        -- Reset
         CLK:       in     bit;        -- Clock
         SYS_CLK:   buffer bit;        -- Systemclock = heruntergeteilte Clock
         R_T:       in     bit;        -- Receiver/Ttansmitter Modus
         TD:        buffer bit;        -- Manchester- Ausgang 
         RD:        in     bit;        -- Manchester- Eingang
         D_OUT:     in     bit;        -- Dateneingang und Programmierquittung
         D_IN:      buffer bit;        -- Datenausgang
         D_CLK:     in     bit;        -- Quittungs und Datenclock
         READY:     buffer bit;        -- Quittungssignal
         CR_DETECT: in     bit;        -- Traeger erkannt
         IRQ:       inout  std_logic;  -- Interrupt-Request
         OVERFLOW:  buffer bit;        -- Datenueberlauffehler
         VALID:     in     bit;        -- Gueltigkeitssignal fuer Daten Ein/Ausgang
         BUSY:      buffer bit;        -- Baustein beschaeftigt
         CR_BUSY:   buffer bit;        -- ODER- Verknuepfung von CR_DETECT und BUSY
         C_D_IN:    buffer bit;        -- Kommando/Datensequenz empfangen
         C_D_OUT:   in     bit;        -- Kommando/Datensequenz senden
         E_TIME:    buffer bit;        -- Timing- Fehler
         E_PARITY:  buffer bit;        -- Paritaets- Fehler
         ERR:       buffer bit         -- Alle Fehler     
       );

end MAN_II;

-----------------------------------------------------------------------------
architecture MAN_II_ARCH of MAN_II is

  type state is range 0 to 23;
  constant n: integer := 16;
  signal DATA_REG:  bit_vector( 0 to n-2 );
  signal TFR_REG:   bit_vector( 0 to n-1 );
  signal Status:    state := 0;
  signal count:     bit_vector( 3 downto 0 ) := "0000";
  signal Parity:    bit := '0';
  signal S1:        bit := '0';
  signal S2:        bit := '0';
  signal cm_dat:    bit;
  signal C_D_OUTi:  bit;
  signal in_M_reg:  bit := '0';
  alias  out_M_reg: bit is TFR_REG( n-1 ); -- Ausgang vom letzten Flipflop
  alias  invers:    bit is count(3);
  alias  A:         bit is RD;
  signal scaler:    bit_vector( 3 downto 0 ) := "1111";
  alias  sc_wert:   bit_vector( 3 downto 0 ) is DATA_REG( 4 to 7 );
  signal ID_REG:    bit_vector( 5 downto 0 ) := "000000";
  alias  id_wert:   bit_vector( 5 downto 0 ) is DATA_REG( 4 to 9 );
  alias  id_cmp:    bit_vector( 5 downto 0 ) is TFR_REG( 0 to 5 );
  signal irq_reg:   bit_vector( 2 downto 0 ) := "010";
  alias  irq_wert:  bit_vector( 2 downto 0 ) is DATA_REG( 4 to 6 );
  alias  index:     bit_vector( 1 downto 0 ) is DATA_REG( 2 to 3 );
  
  signal count1:    bit := '0';
  signal count7:    bit := '0';
  signal count15:   bit := '0';
    
  signal regPtr0:   bit := '0';
  signal regPtr1:   bit := '0';
  signal regPtr15:  bit := '0';
  
begin
--  --  --  --  --  --  -- programmierbarer Frequenzteiler --  --  --  --  --
preScaler: block
   signal clk_cnt:   bit_vector( 3 downto 0 );
begin  
   pre_scaler: process( CLK )
   begin
      if CLK'event and CLK = '1' then
         if clk_cnt = "0000" then
            SYS_CLK <= not SYS_CLK;
            clk_cnt <= scaler;
         else
            clk_cnt(0) <= not clk_cnt(0);
            clk_cnt(1) <= clk_cnt(1) xor  not clk_cnt(0);
            clk_cnt(2) <= clk_cnt(2) xor (not clk_cnt(0) and not clk_cnt(1));
            clk_cnt(3) <= clk_cnt(3) xor (not clk_cnt(0) and not clk_cnt(1) and not clk_cnt(2));
         end if; 
      end if;
   end process;
end block preScaler;


--  --  --  --  --  -- Programmieren der Funktionsregister --  --  --  --  --  
func_reg: process( RST, D_CLK )
begin
   if RST = '1' then
      scaler  <= "1111";
      ID_REG  <= "000000";
      irq_reg <= "010";
   elsif D_CLK'event and D_CLK = '1' then
      if VALID = '1' and D_OUT = '0' then
         case index is
            when "00" =>
               scaler <= sc_wert;
            when "01" =>
               ID_REG <= id_wert;
            when "10" =>
               irq_reg <= irq_wert;
            when others =>
               null;
         end case;
      end if;
   end if;
end process;

--  --  --  --  --  --  --  Modulo 16 Zaehler fuer Wartezeit --  --  --  --  --
counter: process( Status, SYS_CLK )
begin
   if SYS_CLK'event and SYS_CLK = '1' then
      if Status = 0 or Status = 13 then
         count <= "0000";
      elsif Status = 7 or Status = 12 then
         count <= "0110"; 
      else
         count(0) <= not count(0);
         count(1) <= count(1) xor count(0);
         count(2) <= count(2) xor ( count(0) and count(1) );
         count(3) <= count(3) xor ( count(0) and count(1) and count(2) );
      end if;
   end if;
end process;

count2_7_15: process( count )
begin
   if count = "0001" then
      count1 <= '1';
   else
      count1 <= '0';
   end if;

   if count = "0111" then
      count7 <= '1';
   else
      count7 <= '0';
   end if;
   
   if count = "1111" then
      count15 <= '1';
   else
      count15 <= '0';
   end if;    
end process;

--  --  --  --  --  --  --  Busschieberegister --  --  --  --  --  --  --  --
-- Schieberegister fuer die Eingangsleitung D_IN bzw. fuer die Ausgangsleitung
-- D_OUT.
-- Das Schieberegister wird mit einer Positiven Flanke von C_CLK getaktet, wenn
-- VALID und ERR auf null sind.
-- D_IN entspricht dem Ausgang des letzten Flipflops.
-- Wenn der Status = 15, count = "1111" und regPtr = "0000" ist, wird das
-- Busschieberegister vom Sende- und Empfangsregister vorinitialisiert.
BusReg: block
   signal loadBus:  bit := '0';
begin
   setLoad: process( SYS_CLK )
   begin
      if SYS_CLK'event and SYS_CLK = '1' then
         if Status = 15 and regPtr0 = '1' and count15 = '1' then
            loadBus <= '1';
         else
            loadBus <= '0';
         end if;
      end if;
   end process;

   bus_reg: process( D_CLK, loadBus )
   begin
      if loadBus = '1' then
         DATA_REG <= TFR_REG( 0 to n-2 );
         D_IN     <= TFR_REG( n-1 );
      elsif D_CLK'event and D_CLK = '1' then
         if VALID = '0' and ERR = '0' then
            DATA_REG(0) <= D_OUT;
            sft_bus: for i in 1 to n-2 loop
               DATA_REG(i) <= DATA_REG(i-1);
            end loop;
            D_IN <= DATA_REG( n-2 );
         end if;
      end if;
   end process;
end block BusReg;

--  --  --  Sende und empfangs Register mit Positionszaehler --  --  --  --
-- Das Schieberegister und Posttionszaehler wird bei den entsprechenden
-- Status mit SYS_CLK getakted.
tfrReg: block
   signal load:      bit := '0';
   signal neu:       bit := '0';
   signal shift:     bit := '0';
   signal reg_ptr:   bit_vector( 3 downto 0 ) := "0000";
begin
   tfrModus: process( Status, count1, count15 )
   begin
      if Status = 1 and count1 = '1' then 
         load <= '1';
      else
         load <= '0';
      end if;
      
      if Status = 11 then
         neu  <= '1';
      else
         neu  <= '0';
      end if;
      
      if (Status = 5 and count15 = '1' ) or Status = 14 then
         shift <= '1';
      else
         shift <= '0';
      end if;   
   end process;

   tfr_sft: process( SYS_CLK )
   begin
      if SYS_CLK'event and SYS_CLK = '1' then
         if load = '1' then
            TFR_REG <= DATA_REG & D_IN;
         elsif shift = '1' then
            TFR_REG(0) <= in_M_reg;
            sft_tfr: for i in 1 to n-1 loop
               TFR_REG(i) <= TFR_REG(i-1);
            end loop;
         end if;
      end if;   
   end process; 

   shiftPtr: process( SYS_CLK )
   begin
      if SYS_CLK'event and SYS_CLK = '1' then
         if (load or neu) = '1' then
            reg_ptr <= "0000";
         elsif shift = '1' then
            reg_ptr(0) <= not reg_ptr(0);
            reg_ptr(1) <= reg_ptr(1) xor reg_ptr(0);
            reg_ptr(2) <= reg_ptr(2) xor ( reg_ptr(0) and reg_ptr(1) );
            reg_ptr(3) <= reg_ptr(3) xor ( reg_ptr(0) and reg_ptr(1) and reg_ptr(2) );         
         end if;
      end if;
   end process;   

   regFlags: process( reg_ptr )
   begin
      if reg_ptr = "0000" then
         regPtr0  <= '1';
      else
         regPtr0  <= '0';
      end if;

      if reg_ptr = "0001" then
         regPtr1  <= '1';
      else
         regPtr1  <= '0';
      end if;

      if reg_ptr = "1111" then
         regPtr15 <= '1';
      else
         regPtr15 <= '0';
      end if;
   end process;
end block tfrReg;

--  --  --  --  -- setzen und loeschen von BUSY --  --  --  --  --  --  --
set_BUSY: process( Status, count )
begin
   if Status = 0 or Status = 7 then
      BUSY <= '0';
   elsif Status = 1 or Status = 8 then
      BUSY <= '1';
   end if;
end process;

--  --  --  --  -- setzen von C_D_OUTi --  --  --  --  --  --  --  --  --
setC_D_OUTi: process( D_CLK )
begin
   if D_CLK'event and D_clk = '1' then
      if (VALID and D_OUT) = '1' then
         C_D_OUTi <= C_D_OUT;
      end if;
   end if;
end process;

--  --  --  --  -- setzen und loeschen von READY --  --  --  --  --  --
setREADY: block
   signal presetReady:  bit := '0';
begin
   preset_ready: process( SYS_CLK, RST )
   begin
      if RST = '1' then
         presetReady <= '1';
      elsif SYS_CLK'event and SYS_CLK = '1' then
         if Status = 20 or (Status = 1 and count1 = '1') then
            presetReady <= '1';
         else
            presetReady <= '0';
         end if;
      end if;
   end process;
   
   set_ready: process( D_CLK, presetReady )
   begin
      if presetReady = '1' then
         READY <= R_T;
      elsif D_CLK'event and D_CLK = '1' then
         if VALID = '1' and RST = '0' then
            if R_T = '0' and D_OUT = '1' then
               READY <= '1';
            else
               READY <= '0';
            end if;
         else
            READY <= '0';
         end if;
      end if;
   end process;
end block setREADY;

--  --  --  --  -- setzen und loeschen von IRQ --  --  --  --  --  --  --
setIrq: block
   signal comp:      bit := '0';
   signal preIRQ:    bit := '0';       
begin
   compare: process( id_cmp )
   begin
       if ID_REG = id_cmp then
          comp <= '1';
       else
          comp <= '0';
       end if;
   end process;
   
   set_irq: process( SYS_CLK )
   begin
      if SYS_CLK'event and SYS_CLK = '1' then
         if (Status = 20 and ((irq_reg(1) = '1' and comp = '1' and C_D_IN = '1' and Parity = '0') or
                              (irq_reg(0) = '1' and READY = '0'))) or
            (Status = 1  and count1 = '1' and irq_reg(2) = '1') then
            preIRQ <= '1';
         else
            preIRQ <= '0';   
         end if;
      end if;
   end process;
   
   setTreIRQ: process( preIRQ, RST )
   begin
      if preIRQ = '1' and RST = '0' then
         IRQ <= '0';
      else
         IRQ <= 'Z';
      end if;
   end process;
end block;

--  --  --  --  --  --  Setzen und loeschen der Error-Pins --  --  --  --  --  --  --  --  --
setError: block
   signal preOVERFLOW:   bit := '0';
   signal prePARITY:     bit := '0';
   signal preTIME:       bit := '0';
begin
   preset_error: process( SYS_CLK )
   begin
      if SYS_CLK'event and SYS_CLK = '1' then
         if Status = 20 then
            prePARITY   <= PARITY;
            preOVERFLOW <= READY;
         elsif Status = 21 then
            preTIME     <= '1';
         else
            preOVERFLOW <= '0';
            prePARITY   <= '0';
            preTIME     <= '0';
         end if;
      end if;
   end process;
   
   set_overflow: process( D_CLK, RST, preOVERFLOW )
   begin
      if preOVERFLOW = '1' or RST = '1' then
         OVERFLOW <= not RST;
      elsif D_CLK'event and D_CLK = '1' then
         OVERFLOW <= '0';
      end if;
   end process;
   
   set_parity: process( D_CLK, RST, prePARITY )
   begin
      if prePARITY = '1' or RST = '1' then
         E_PARITY <= not RST;
      elsif D_CLK'event and D_CLK = '1' then
         E_PARITY <= '0';
      end if;
   end process;
   
   set_time: process( D_CLK, RST, preTIME )
   begin
      if preTIME = '1' or RST = '1' then
         E_TIME <= not RST;
      elsif D_CLK'event and D_CLK = '1' then
         E_TIME <= '0';
      end if;
   end process;

   set_err: process( OVERFLOW, E_PARITY, E_TIME )
   begin
      ERR <= OVERFLOW or E_PARITY or E_TIME;
   end process;
end block setError;

--  --  --  --  --  --  setzen und loeschen von CR_BUSY --  --  --  --  --
setCR_BUSY: process( BUSY, CR_DETECT )
begin
   CR_BUSY <= BUSY or CR_DETECT;
end process;

--  --  --  --  --  Eingangsfilter --  --  --  --  --  --  --  --  --  --
filter: block
   signal B:         bit := '0';
   signal C:         bit := '0';
begin
   filterF: process( SYS_CLK )
   begin
      if SYS_CLK'event and SYS_CLK = '1' then
         B <= A;
         C <= B;
      end if;
   end process;

   filterL: process( A, B, C )
   begin
      S2 <= ((A and B and C) or (A and B and not C) or 
            (A and not B and C) or (not A and B and C));
   end process; 
end block;

--  --  --  --  --  --  --  Merker fuer S2 --  --  --  --  --  --  --  --
pipe: process( SYS_CLK )
begin
   if SYS_CLK'event and SYS_CLK = '1' then
      S1 <= S2;
   end if;
end process;   

--  --  --  --  --  --  -- Hauptfunktion --  --  --  --  --  --  --  --  -- 
main: process( SYS_CLK, RST )
begin
   if RST = '1' then
      Status <= 0;
   elsif SYS_CLK'event AND SYS_CLK = '1' then
      case Status is
      
         when 0 =>
            if R_T = '0' and READY = '1' then
               Status <= 1;   -- gehe zum Sendealgorithmus
            elsif R_T = '1' then
               Status <= 7;  -- gehe zum Empfangsalgorithmus
            end if;
                                      
         when 1 =>
            if count = "0000" then
               Parity <= '1';
               TD <= C_D_OUTi;
            elsif count15 = '1' then -- Volle Bitzeit abgelaufen ?
               Status <= 2;        
            end if;
                   
         when 2 =>
            if count7 = '1' then     -- 1,5-fache Bitzeit abgelaufen ?
               Status <= 3;        
            end if;
            
         when 3 =>
            if count = "1000" then
              TD <= not TD;          -- Signal invertieren.
            elsif count15 = '1' then -- Halbe Bitzeit seit Wechsel abgelaufen ?
               Status <= 4;        
            end if;
                   
         when 4 =>
            if count15 = '1' then    -- Volle Bitzeit abgelaufen ?
               Status <= 5;       
            end if;

         when 5 =>    -- Datenbits aussenden
            if count15 = '1' then
               if regPtr15 = '1' then
                  Status <= 6;
               end if;
               Parity <= Parity xor out_M_reg;
            else
               TD <= invers xor out_M_reg;
            end if;

         when 6 =>   -- Paritaetsbit aussenden
            if count15 = '1' then
               if R_T = '0' and READY = '1' then
                  Status <= 1;
               else
                  Status <= 0;
               end if;
            else
               TD <= Parity xor invers;
            end if;
            
--  --  --  --  --  --  --  Empfangssequenzen --  --  --  --  --  --  --  --            
         
         when 7 =>
            if R_T = '0' then
               Status <= 0;
            elsif ((S1 xor S2) and CR_DETECT) = '1' then
               Status <= 8;
            end if;
            Parity <= '1';   -- Achtung Paritaetsflag ist hier ein Synchrnisationflag
                             -- damit Status 13 pro Synchonisation nur einmahl durchlaufen wird.
         when 8 =>
            if R_T = '0' then
               Status <= 0;
            elsif (S1 xor S2) = '1' then
               Status <= 7;
            elsif count15 = '1' then
               Status <= 9;
            end if;
                   
         when 9 =>
            if R_T = '0' then
               Status <= 0;
            elsif (S1 xor S2) = '1' then
               Status <= 7;
            elsif count7 = '1' then
               Status <= 10;
            end if;
            cm_dat <= S1;
            
         when 10 =>
            if R_T = '0' then
               Status <= 0;
            elsif count15 = '1' then
               Status <= 11;
            end if;
            
         when 11 =>
            if R_T = '0' then
               Status <= 0;
            elsif (S1 xor S2) = '1' then
               Parity <= '1';        -- Paritaet auf ungerade initialisieren
               Status <= 12;
            elsif count7 = '1' then
               if Parity = '1' then
                  Status <= 13;
               else
                  Status <= 7;
               end if;
            end if;
            
         when 12 =>
            if regPtr1 = '1' then
               C_D_IN <= not cm_dat;   
            end if;
            in_M_reg <= not S1;
            Parity <= Parity xor not S1;
            Status <= 14;
            
         when 13 =>
            Parity <= '0';          -- Synchronisetionsflag loeschen
            Status <= 9;
            
         when 14 =>
            Status <= 15;
                        
         when 15 =>
            if count15 = '1' then
               if regPtr0 = '1' then
                  Status <= 19;
               else
                  Status <= 16;
               end if;
            end if;
            
         when 16 =>
            if (S1 xor S2) = '1' then
               Status <= 12;
            elsif count7 = '1' then
               if regPtr1 = '1' then
                  cm_dat <= not TFR_REG(0);
                  Parity <= '0';    -- Synchronisetionsflag loeschen
                  Status <= 10;
               else
                  Status <= 21;
               end if;
            end if;
                        
         when 19 =>
            if (S1 xor S2) = '1' then
               Parity <= Parity xor S1;
               Status <= 20;
            elsif count7 = '1' then
               Status <= 21;
            end if;
          
         when 20 =>
            if R_T = '1' then
               Status <= 7;
            else
               Status <= 0;
            end if;

         when 21 =>    -- Timing error
            if R_T = '1' then
               Status <= 7;
            else
               Status <= 0;
            end if;
            
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --              
         when others =>
            Status <= 0;
            
      end case;      
   end if;
end process;

end MAN_II_ARCH;

-----------------------------------------------------------------------------
configuration MAN_II_CFG of MAN_II is

    for MAN_II_ARCH
    end for;
    
end MAN_II_CFG;
