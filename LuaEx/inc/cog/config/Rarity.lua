return {
    Affix = {
        maxTier = TIER.VI,--NOTE: every rarity's maximum affix tier must be no higher than this cap
    },
    --[[!
    @fqxn CoG.Rarity.Enums.LEVEL
    @pulsarlua table Rarity.LEVEL
    @desc
    <div class="text-center" style="margin: 20px;">
        <div class="alert" style="background-color: #CCDC90; color: #333333; border-radius: 15px; padding: 10px; display: inline-block;">
            <b>The Following Table Details the Rarity Levels and Corresponding Color, Chance, and Affix Tiers</b>
            <br>
            <i>Rarity levels are defined in CoG's <a href="#CoG.Config" style="color: #00797d;">config</a> file.</i>
        </div>
    </div>
    <table class="table table-bordered">
        <thead>
            <tr>
                <th style="background-color: #CCDC90; color: #000000;">Level</th>
                <th style="background-color: #CCDC90; color: #000000;">Color</th>
                <th style="background-color: #CCDC90; color: #000000;">Chance (%)</th>
                <th style="background-color: #CCDC90; color: #000000;">Min Affix Tier</th>
                <th style="background-color: #CCDC90; color: #000000;">Max Affix Tier</th>
                <th style="background-color: #CCDC90; color: #000000;">Min Prefixes</th>
                <th style="background-color: #CCDC90; color: #000000;">Max Prefixes</th>
                <th style="background-color: #CCDC90; color: #000000;">Min Suffixes</th>
                <th style="background-color: #CCDC90; color: #000000;">Max Suffixes</th>
            </tr>
        </thead>
        <tbody style="background-color: #3F3F3F; color: #DCDCCC;">
            <tr>
                <td><b>COMMON</b></td>
                <td style="background-color: #BBBBBB; color: black;">#BBBBBB</td>
                <td>100</td>
                <td>TIER.I</td>
                <td>TIER.I</td>
                <td>0</td>
                <td>1</td>
                <td>0</td>
                <td>1</td>
            </tr>
            <tr>
                <td><b>UNCOMMON</b></td>
                <td style="background-color: #0000B3; color: white;">#0000B3</td>
                <td>21</td>
                <td>TIER.I</td>
                <td>TIER.II</td>
                <td>1</td>
                <td>1</td>
                <td>1</td>
                <td>2</td>
            </tr>
            <tr>
                <td><b>RARE</b></td>
                <td style="background-color: #AFC657; color: black;">#AFC657</td>
                <td>11</td>
                <td>TIER.I</td>
                <td>TIER.III</td>
                <td>1</td>
                <td>2</td>
                <td>1</td>
                <td>2</td>
            </tr>
            <tr>
                <td><b>EPIC</b></td>
                <td style="background-color: #00C202; color: white;">#00C202</td>
                <td>6</td>
                <td>TIER.II</td>
                <td>TIER.IV</td>
                <td>2</td>
                <td>2</td>
                <td>2</td>
                <td>3</td>
            </tr>
            <tr>
                <td><b>LEGENDARY</b></td>
                <td style="background-color: #BA0000; color: white;">#BA0000</td>
                <td>3</td>
                <td>TIER.II</td>
                <td>TIER.V</td>
                <td>2</td>
                <td>3</td>
                <td>3</td>
                <td>3</td>
            </tr>
            <tr>
                <td><b>SINGULAR</b></td>
                <td style="background-color: #CF7136; color: white;">#CF7136</td>
                <td>1</td>
                <td>TIER.V</td>
                <td>TIER.VI</td>
                <td>3</td>
                <td>3</td>
                <td>3</td>
                <td>3</td>
            </tr>
        </tbody>
    </table>
    !]]
    LEVEL               = {"COMMON",    "UNCOMMON",     "RARE",         "EPIC",     "LEGENDARY",    "SINGULAR"},
    COLOR               = {"#BBBBBB",   "#0000B3",      "#AFC657",      "#00C202",  "#BA0000",      "#CF7136"},
    -- Cumulative integer thresholds must start at 100 and never increase.
    -- Equal thresholds allow a level with zero random occurrence probability.
    -- Actual rates here are 79%, 10%, 5%, 3%, 2%, 1%.
    CHANCE              = {100,         21,             11,             6,          3,              1},
    MIN_AFFIX_TIER      = {TIER.I,      TIER.I,         TIER.I,         TIER.II,    TIER.II,        TIER.V},
    MAX_AFFIX_TIER      = {TIER.I,      TIER.II,        TIER.III,       TIER.IV,    TIER.V,         TIER.VI},
    MIN_PREFIXES        = {0,           1,              1,              2,          2,              3},
    MAX_PREFIXES        = {1,           1,              2,              2,          3,              3},
    MIN_SUFFIXES        = {0,           1,              1,              2,          3,              3},
    MAX_SUFFIXES        = {1,           2,              2,              3,          3,              3},
};
