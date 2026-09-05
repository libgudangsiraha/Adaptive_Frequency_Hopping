function name = get_adversary_display_name(adversaryType)
%GET_ADVERSARY_DISPLAY_NAME Publication-facing adversary name.

    switch lower(string(adversaryType))
        case "none"
            name = "No active jammer";
        case "random"
            name = "Random jammer";
        case "sweep"
            name = "Sweep jammer";
        case "folpetti_ts"
            name = "FOLPETTI-inspired TS";
        case "contextual_expert"
            name = "Contextual-expert white-box";
        case "contextual_online"
            name = "Contextual online predictor";
        otherwise
            name = string(adversaryType);
    end

end
