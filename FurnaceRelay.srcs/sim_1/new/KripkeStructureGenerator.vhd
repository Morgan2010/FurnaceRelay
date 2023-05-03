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
        finished => true
    ));
    
    signal currentJobs: CurrentJobs_t := (others => false);

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
    constant Finished: std_logic_vector(3 downto 0) := "0111";
    
    signal genTracker: std_logic_vector(3 downto 0) := Setup;
    
    signal observedStates: AllStates_t;
    signal pendingStates: AllStates_t;

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
variable observedStatesIndex: integer range 0 to 5 := 0;
variable pendingStatesIndex: integer range 0 to 5 := 0;
begin
if rising_edge(clk) then
    case genTracker is
        when Setup =>
            pendingStates(0) <= (
                state => STATE_Initial,
                executeOnEntry => true,
                observed => true
            );
            genTracker <= ChooseNextState;
        when StartExecuting =>
            reset <= '1';
            genTracker <= WaitUntilStart;
        when WaitUntilStart =>
            reset <= '0';
            genTracker <= WaitUntilFinish;
        when WaitUntilFinish =>
            for i in 0 to 1611 loop
                if currentJobs(i) then
                    if runners(i).finished then
                        genTracker <= UpdateKripkeStates;
                    end if;
                end if;
            end loop;
        when UpdateKripkeStates =>
            for i in 0 to 1611 loop
                if currentJobs(i) then
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
                                for os in 0 to 5 loop
                                    if observedStates(os).observed and observedStates(os).state = runners(i).state and observedStates(os).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                        exit;
                                    elsif os >= observedStatesIndex and not observedStates(os).observed then
                                        observedStates(os) <= (state => runners(i).state, executeOnEntry => runners(i).readSnapshotState.executeOnEntry, observed => true);
                                        observedStatesIndex := observedStatesIndex + 1;
                                        exit;
                                    end if;
                                end loop;
                                for ps in 0 to 5 loop
                                    if pendingStates(ps).observed and pendingStates(ps).state = runners(i).nextState and pendingStates(ps).executeOnEntry = (runners(i).previousRinglet /= runners(i).nextState) then
                                        exit;
                                    elsif ps >= pendingStatesIndex and not pendingStates(ps).observed then
                                        pendingStates(ps) <= (
                                            state => runners(i).nextState,
                                            executeOnEntry => runners(i).previousRinglet /= runners(i).nextState,
                                            observed => true
                                        );
                                        pendingStatesIndex := pendingStatesIndex + 1;
                                        exit;
                                    end if;
                                end loop;
                            else
                                -- When i>0, Check all previous current jobs for the same snapshots and the saved snapshots before adding a new entry into the saved snapshot buffers. 
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState = runners(i).readSnapshotState) then
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
                                    if currentJobs(rsi) and (runners(rsi).writeSnapshotState = runners(i).writeSnapshotState) then
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
                                    if currentJobs(rsi) and (runners(rsi).state = runners(i).state) and (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for os in 0 to 5 loop
                                            if observedStates(os).observed and observedStates(os).state = runners(i).state and observedStates(os).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                                exit;
                                            elsif os >= observedStatesIndex and not observedStates(os).observed then
                                                observedStates(os) <= (state => runners(i).state, executeOnEntry => runners(i).readSnapshotState.executeOnEntry, observed => true);
                                                observedStatesIndex := observedStatesIndex + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                    if currentJobs(rsi) and (runners(rsi).nextState = runners(i).nextState) and ((runners(rsi).previousRinglet /= runners(rsi).nextState) = (runners(i).previousRinglet /= runners(i).nextState)) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for ps in 0 to 5 loop
                                            if pendingStates(ps).observed and pendingStates(ps).state = runners(i).nextState and pendingStates(ps).executeOnEntry = (runners(i).previousRinglet /= runners(i).nextState) then
                                                exit;
                                            elsif ps >= pendingStatesIndex and not pendingStates(ps).observed then
                                                pendingStates(ps) <= (
                                                    state => runners(i).nextState,
                                                    executeOnEntry => runners(i).previousRinglet /= runners(i).nextState,
                                                    observed => true
                                                );
                                                pendingStatesIndex := pendingStatesIndex + 1;
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
        when ClearJobs =>
            currentJobs <= (others => false);
            for j in 0 to 5 loop
                for p in 0 to 5 loop
                    if pendingStates(p).observed then
                        if pendingStates(p) = observedStates(j) then
                            pendingStates(p).observed <= false;
                        end if;
                    end if;
                end loop;
            end loop;
            genTracker <= ChooseNextState;
        when ChooseNextState =>
            for s in 0 to 5 loop
                if pendingStates(s).observed then
                    case pendingStates(s).state is
                        when STATE_Initial =>
                            currentJobs(0) <= true;
                            runners(0).state <= STATE_Initial;
                            if pendingStates(s).executeOnEntry then
                                runners(0).previousRinglet <= "ZZ";
                            else
                                runners(0).previousRinglet <= STATE_Initial;
                            end if;
                        when others =>
                            null;
                    end case;
                    genTracker <= StartExecuting;
                    exit;
                elsif s = 5 then
                    genTracker <= Finished;
                end if;
            end loop;
        when others =>
            null;
    end case;
end if;
end process;

end Behavioral;
