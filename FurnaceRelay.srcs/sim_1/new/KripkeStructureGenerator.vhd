----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 05:51:12
-- Design Name: 
-- Module Name: KripkeStructureGenerator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.FR_KripkeTypes2.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity KripkeStructureGenerator is
--  Port ( );
end KripkeStructureGenerator;

architecture Behavioral of KripkeStructureGenerator is
    signal clk: std_logic := '0';
    signal initialReadSnapshots: Initial_ReadSnapshots_t;
    signal initialWriteSnapshots: Initial_WriteSnapshots_t;
    signal initialEdges: Initial_Edges_t;
    signal reset: std_logic := '0';
    signal runners: Runners_t := (others => (
        state => "00",
        demand => "00",
        heat => '0',
        previousRinglet => "ZZ",
        readSnapshotState => (
            demand => "00",
            heat => '0',
            state => "00",
            executeOnEntry => true
        ),
        writeSnapshotState => (
            demand => "00",
            heat => '0',
            relayOn => '0',
            state => "00",
            executeOnEntry => true
        ),
        nextState => "00",
        finished => true,
        observed => false
    ));

    component RingletRunner is
    port(
        clk: in std_logic;
        reset: in std_logic := '0';
        state: in std_logic_vector(1 downto 0) := "00";
        demand: in std_logic_vector(1 downto 0) := "00";
        heat: in std_logic := '0';
        previousRinglet: in std_logic_vector(1 downto 0) := "ZZ";
        readSnapshotState: out ReadSnapshot_t;
        writeSnapshotState: out WriteSnapshot_t;
        nextState: out std_logic_vector(1 downto 0);
        finished: out boolean := true
    );
    end component;
    
    constant Setup: std_logic_vector(3 downto 0) := "0000";
    constant StartExecuting: std_logic_vector(3 downto 0) := "0001";
    constant WaitUntilFinish: std_logic_vector(3 downto 0) := "0010";
    constant UpdateKripkeStates: std_logic_vector(3 downto 0) := "0011";
    constant WaitUntilStart: std_logic_vector(3 downto 0) := "0100";
    constant ChooseNextState: std_logic_vector(3 downto 0) := "0101";
    constant ClearJobs: std_logic_vector(3 downto 0) := "0110";
    
    signal genTracker: std_logic_vector(3 downto 0) := Setup;

begin

clk <= not clk after 10ns;

run_gen: for i in 0 to 1611 generate
    run_inst: RingletRunner port map(
        clk => clk,
        reset => reset,
        state => runners(i).state,
        demand => runners(i).demand,
        heat => runners(i).heat,
        previousRinglet => runners(i).previousRinglet,
        readSnapshotState => runners(i).readSnapshotState,
        writeSnapshotState => runners(i).writeSnapshotState,
        nextState => runners(i).nextState,
        finished => runners(i).finished
    );
end generate run_gen;

process(clk)
variable initialReadSnapshotIndex: integer range 0 to 1 := 0;
variable initialWriteSnapshotIndex: integer range 0 to 1 := 0;
variable initialEdgeIndex: integer range 0 to 1 := 0;
begin
if rising_edge(clk) then
    case genTracker is
        when Setup =>
            runners(0).observed <= true;
            genTracker <= StartExecuting;
        when StartExecuting =>
            reset <= '1';
            genTracker <= WaitUntilStart;
        when WaitUntilStart =>
            reset <= '0';
            genTracker <= WaitUntilFinish;
        when WaitUntilFinish =>
            for i in 0 to 1611 loop
                if runners(i).observed then
                    if runners(i).finished then
                        genTracker <= UpdateKripkeStates;
                    end if;
                end if;
            end loop;
        when UpdateKripkeStates =>
            for i in 0 to 1611 loop
                if runners(i).observed then
                    case runners(i).state is
                        when STATE_Initial =>
                            -- When i=0, Check existing saved snapshots before writing new snapshot into buffer.
                            if i = 0 then
                                for rs in 0 to 1 loop
                                    if (initialReadSnapshots(rs).observed and initialReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rs >= initialReadSnapshotIndex and not initialReadSnapshots(rs).observed then
                                        initialReadSnapshots(rs) <= (
                                            executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        initialReadSnapshotIndex := initialReadSnapshotIndex + 1;
                                        exit;
                                    end if;
                                end loop;
                                for ws in 0 to 1 loop
                                    if (initialWriteSnapshots(ws).observed and initialWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif ws >= initialWriteSnapshotIndex and not initialWriteSnapshots(ws).observed then
                                        initialWriteSnapshots(ws) <= (
                                            executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        initialWriteSnapshotIndex := initialWriteSnapshotIndex + 1;
                                        exit;
                                    end if;
                                end loop;
                                for ed in 0 to 1 loop
                                    if (initialEdges(ed).observed and initialEdges(ed).writeSnapshot = (executeOnEntry => runners(i).writeSnapshotState.executeOnEntry, observed => true) and initialEdges(ed).nextState = runners(i).nextState) then
                                        exit;
                                    elsif ed >= initialEdgeIndex and not initialEdges(ed).observed then
                                        initialEdges(ed) <= (
                                            writeSnapshot => (
                                                executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                                observed => true
                                            ),
                                            nextState => runners(i).nextState,
                                            observed => true
                                        );
                                        initialEdgeIndex := initialEdgeIndex + 1;
                                        exit;
                                    end if;
                                end loop;
                            else
                                -- When i>0, Check all previous current jobs for the same snapshots and the saved snapshots before adding a new entry into the saved snapshot buffers. 
                                for rsi in 0 to (i - 1) loop
                                    if runners(rsi).observed and (runners(rsi).readSnapshotState = runners(i).readSnapshotState) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for rs in 0 to 1 loop
                                            if (initialReadSnapshots(rs).observed and initialReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                                exit;
                                            elsif rs >= initialReadSnapshotIndex and not initialReadSnapshots(rs).observed then
                                                initialReadSnapshots(rs) <= (
                                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                initialReadSnapshotIndex := initialReadSnapshotIndex + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                    if runners(rsi).observed and (runners(rsi).writeSnapshotState = runners(i).writeSnapshotState) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for ws in 0 to 1 loop
                                            if (initialWriteSnapshots(ws).observed and initialWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) then
                                                exit;
                                            elsif ws >= initialWriteSnapshotIndex and not initialWriteSnapshots(ws).observed then
                                                initialWriteSnapshots(ws) <= (
                                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                initialWriteSnapshotIndex := initialWriteSnapshotIndex + 1;
                                                exit;
                                            end if;
                                        end loop;
                                        for ed in 0 to 1 loop
                                            if (initialEdges(ed).observed and initialEdges(ed).writeSnapshot = (executeOnEntry => runners(i).writeSnapshotState.executeOnEntry, observed => true) and initialEdges(ed).nextState = runners(i).nextState) then
                                                exit;
                                            elsif ed >= initialEdgeIndex and not initialEdges(ed).observed then
                                                initialEdges(ed) <= (
                                                    writeSnapshot => (
                                                        executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                                        observed => true
                                                    ),
                                                    nextState => runners(i).nextState,
                                                    observed => true
                                                );
                                                initialEdgeIndex := initialEdgeIndex + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                            end if;
                        when others =>
                            null;
                    end case;
                end if;
            end loop;
            genTracker <= ClearJobs;
--        when ClearJobs =>
--            for i in 0 to 1611 loop
--                runners(i).observed <= false;
--            end loop;
--            genTracker <= ChooseNextState;
        when others =>
            null;
    end case;
end if;
end process;

end Behavioral;
