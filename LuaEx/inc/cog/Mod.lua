local envrepo   = envrepo;
local rawtype   = rawtype;
local type      = type;
local class     = class;
local EnvMan    = EnvMan;
local Folder    = Folder;
local File      = File;
local pairs     = pairs;

return class("Mod",
{--METAMETHODS

},
{--STATIC PUBLIC
    IMAGE_BASE_PATH = "Images",
    --Mod = function(stapub) end,
    loadMods = function()
        local tModFolders = Folder.Find(_Mods, "*", false, nil);

        if (tModFolders) then

            for _, pFolder in pairs(tModFolders) do
                local pModInfo = pFolder.."\\modinfo.lua";

                if (File.DoesExist(pModInfo)) then
                    --check that the file is valid lua TODO THIS NEEDS DELETEED ALONG EITH ENVMAN
                    local bRet, sMessage, fChunk = EnvMan.validateFile(pModInfo);

                    if not (bRet) then
                        error("Error reading modinfo.lua:\n"..sMessage);
                    end

                    --create the mod
                    local oMod = Mod(pFolder, fChunk());
                    --local bIsValid, sMessage, tModInfo = modInfoIsValid(fChunk);

                --    if not (bIsValid) then
                    --    error("Error in modinfo.lua:\n"..sMessage);
                --    end
                --TODO FINISH SAFE LOAD AND CHECKS including if mod already exists (using ID)
                    _tMods[oMod.getID()] = oMod;

                    --load in the blueprints
                    local pBPs = pFolder.."\\Blueprints.lua";

                    if (File.DoesExist(pBPs)) then
                        local sBPs  = TextFile.ReadToString(pBPs);
                        local fBPs  = load(sBPs);

                        if not (type(fBPs) == "function") then
                            --TODO THROW/LOG ERROR
                        end

                        --save the old env and load in the safe one
                        local wOld  = _ENV;
                        _ENV        = envrepo["Mod"];

                        --create the BPs table (in the safe env)
                        local tBPs  = fBPs;

                        --load in the old env
                        _ENV = wOld;

                        --[[
                         █████╗ ███████╗███████╗██╗██╗  ██╗███████╗███████╗
                        ██╔══██╗██╔════╝██╔════╝██║╚██╗██╔╝██╔════╝██╔════╝
                        ███████║█████╗  █████╗  ██║ ╚███╔╝ █████╗  ███████╗
                        ██╔══██║██╔══╝  ██╔══╝  ██║ ██╔██╗ ██╔══╝  ╚════██║
                        ██║  ██║██║     ██║     ██║██╔╝ ██╗███████╗███████║
                        ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝]]
                        --load in the 🅿🆁🅴🅵🅸🆇🅴🆂 and 🆂🆄🅵🅵🅸🆇🅴🆂
                        if (type(tBPs.Affix) == "table") then

                            for _, tAffix in pairs(tBPs.Affix) do
                                --TODO validate affix table
                                local bSuccess, bImported = Blueprint.import(Affix, tAffix);

                                if (bSuccess) then
                                    --TODO REGISTER AFFIX WITH AFFIXMAN
                                else
                                    --TODO ERROR
                                end

                            end

                        end




                    end


















                    --AffixMan


                    --TODO load in items and other mod things
                end

            end

        end

        local tFiles = File.Find(_Scripts.."\\", "*.*", false, false, nil, nil);
    end,
},
{--PRIVATE
},
{},--PROTECTED
{--PUBLIC
    Mod = function(this, cdat, pFolder)
        super(pFolder);
    end,
},
BaseMod, --extending class
true,    --if the class is final
nil      --interface(s) (either nil, or interface(s))
);
