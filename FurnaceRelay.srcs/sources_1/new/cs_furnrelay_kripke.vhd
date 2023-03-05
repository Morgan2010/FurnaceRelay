library IEEE;
use IEEE.std_logic_1164.All;

package cs_furnrelay_kripke is

type cs_KripkeState is record
    state: std_logic_vector(2 downto 0);
    demand: std_logic;
    ins_seasonswitch: std_logic_vector(2 downto 0);
    instate: std_logic_vector(2 downto 0);
end record cs_KripkeState; 

end package cs_furnrelay_kripke;