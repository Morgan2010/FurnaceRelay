library IEEE;
use IEEE.std_logic_1164.All;
use IEEE.math_real.All;

entity FurnaceRelay is
    port(
        clk: in std_logic;
        EXTERNAL_demand: in std_logic_vector(1 downto 0) := (others => '0');
        EXTERNAL_Heat: in std_logic := '0';
        EXTERNAL_RelayOn: out std_logic := '0';
        FurnaceRelay_demand: out std_logic_vector(1 downto 0);
        FurnaceRelay_heat: out std_logic;
        FurnaceRelay_relayOn: out std_logic;
        FurnaceRelay_relayOnIn: in std_logic;
        FurnaceRelay_currentStateIn: in std_logic_vector(1 downto 0);
        FurnaceRelay_previousRingletIn: in std_logic_vector(1 downto 0);
        FurnaceRelay_internalStateIn: in std_logic_vector(2 downto 0);
        FurnaceRelay_currentStateOut: out std_logic_vector(1 downto 0) := "00";
        FurnaceRelay_targetStateIn: in std_logic_vector(1 downto 0) := "00";
        FurnaceRelay_targetStateOut: out std_logic_vector(1 downto 0) := "00";
        FurnaceRelay_previousRingletOut: out std_logic_vector(1 downto 0) := "ZZ";
        FurnaceRelay_internalStateOut: out std_logic_vector(2 downto 0);
        setInternalSignals: in std_logic;
        reset: in std_logic
    );
end FurnaceRelay;

architecture Behavioral of FurnaceRelay is
    -- Internal State Representation Bits
    constant CheckTransition: std_logic_vector(2 downto 0) := "000";
    constant Internal: std_logic_vector(2 downto 0) := "001";
    constant NoOnEntry: std_logic_vector(2 downto 0) := "010";
    constant OnEntry: std_logic_vector(2 downto 0) := "011";
    constant OnExit: std_logic_vector(2 downto 0) := "100";
    constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
    constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";
    signal internalState: std_logic_vector(2 downto 0) := ReadSnapshot;
    -- State Representation Bits
    constant STATE_Initial: std_logic_vector(1 downto 0) := "00";
    constant STATE_FROff: std_logic_vector(1 downto 0) := "01";
    constant STATE_FROn: std_logic_vector(1 downto 0) := "10";
    signal currentState: std_logic_vector(1 downto 0) := STATE_Initial;
    signal targetState: std_logic_vector(1 downto 0) := STATE_Initial;
    signal previousRinglet: std_logic_vector(1 downto 0) := "ZZ";
    -- Snapshot of External Signals and Variables
    signal demand: std_logic_vector(1 downto 0);
    signal Heat: std_logic;
    signal RelayOn: std_logic;
begin

    FurnaceRelay_demand <= demand;
    FurnaceRelay_heat <= heat;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if reset = '1' then
                FurnaceRelay_relayOn <= RelayOn;
                case internalState is
                    when CheckTransition =>
                        case currentState is
                            when STATE_Initial =>
                                targetState <= STATE_FROff;
                                FurnaceRelay_targetStateOut <= STATE_FROff;
                                internalState <= OnExit;
                                FurnaceRelay_internalStateOut <= OnExit;
                            when STATE_FROff =>
                                if (demand = "10" and Heat = '1') then
                                    targetState <= STATE_FROn;
                                    FurnaceRelay_targetStateOut <= STATE_FROn;
                                    internalState <= OnExit;
                                    FurnaceRelay_internalStateOut <= OnExit;
                                else
                                    internalState <= Internal;
                                    FurnaceRelay_internalStateOut <= Internal;
                                end if;
                            when STATE_FROn =>
                                if (demand = "01") then
                                    targetState <= STATE_FROff;
                                    FurnaceRelay_targetStateOut <= STATE_FROff;
                                    internalState <= OnExit;
                                    FurnaceRelay_internalStateOut <= OnExit;
                                else
                                    internalState <= Internal;
                                    FurnaceRelay_internalStateOut <= Internal;
                                end if;
                            when others =>
                                internalState <= Internal;
                                FurnaceRelay_internalStateOut <= Internal;
                        end case;
                        FurnaceRelay_currentStateOut <= currentState;
                    when Internal =>
                        internalState <= WriteSnapshot;
                        FurnaceRelay_internalStateOut <= WriteSnapshot;
                        FurnaceRelay_currentStateOut <= currentState;
                    when NoOnEntry =>
                        internalState <= CheckTransition;
                        FurnaceRelay_internalStateOut <= CheckTransition;
                        FurnaceRelay_currentStateOut <= currentState;
                    when OnEntry =>
                        case currentState is
                            when STATE_FROff =>
                                RelayOn <= '0';
                            when STATE_FROn =>
                                RelayOn <= '1';
                            when others =>
                                null;
                        end case;
                        internalState <= CheckTransition;
                        FurnaceRelay_internalStateOut <= CheckTransition;
                        FurnaceRelay_currentStateOut <= currentState;
                    when OnExit =>
                        internalState <= WriteSnapshot;
                        FurnaceRelay_internalStateOut <= WriteSnapshot;
                        FurnaceRelay_currentStateOut <= currentState;
                    when ReadSnapshot =>
                        case currentState is
                            when STATE_FROff =>
                                demand <= EXTERNAL_demand;
                                Heat <= EXTERNAL_Heat;
                            when STATE_FROn =>
                                demand <= EXTERNAL_demand;
                            when others =>
                                null;
                        end case;
                        if (previousRinglet /= currentState) then
                            internalState <= OnEntry;
                            FurnaceRelay_internalStateOut <= OnEntry;
                        else
                            internalState <= NoOnEntry;
                            FurnaceRelay_internalStateOut <= NoOnEntry;
                        end if;
                        FurnaceRelay_currentStateOut <= currentState;
                    when WriteSnapshot =>
                        case currentState is
                            when STATE_FROff =>
                                EXTERNAL_RelayOn <= RelayOn;
                            when STATE_FROn =>
                                EXTERNAL_RelayOn <= RelayOn;
                            when others =>
                                null;
                        end case;
                        internalState <= ReadSnapshot;
                        FurnaceRelay_internalStateOut <= ReadSnapshot;
                        previousRinglet <= currentState;
                        FurnaceRelay_previousRingletOut <= currentState;
                        currentState <= targetState;
                        FurnaceRelay_currentStateOut <= targetState;
                    when others =>
                        FurnaceRelay_internalStateOut <= internalState;
                        FurnaceRelay_currentStateOut <= currentState;
                        FurnaceRelay_previousRingletOut <= previousRinglet;
                        FurnaceRelay_targetStateOut <= targetState;
                end case;
            else
                if setInternalSignals = '1' then
                    currentState <= FurnaceRelay_currentStateIn;
                    previousRinglet <= FurnaceRelay_previousRingletIn;
                    internalState <= FurnaceRelay_internalStateIn;
                    targetState <= FurnaceRelay_targetStateIn;
                    FurnaceRelay_currentStateOut <= FurnaceRelay_currentStateIn;
                    FurnaceRelay_previousRingletOut <= FurnaceRelay_previousRingletIn;
                    FurnaceRelay_internalStateOut <= FurnaceRelay_internalStateIn;
                    FurnaceRelay_targetStateOut <= FurnaceRelay_targetStateIn;
                    relayOn <= FurnaceRelay_relayOnIn;
                else
                    FurnaceRelay_currentStateOut <= currentState;
                    FurnaceRelay_previousRingletOut <= previousRinglet;
                    FurnaceRelay_internalStateOut <= internalState;
                    FurnaceRelay_targetStateOut <= targetState;
                    FurnaceRelay_relayOn <= RelayOn;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
