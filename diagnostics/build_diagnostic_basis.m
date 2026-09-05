function Phi = build_diagnostic_basis(X, basisType)
%BUILD_DIAGNOSTIC_BASIS Linear and deliberately richer nonlinear bases.

    X = min(max(X, 0), 1);
    basisType = lower(string(basisType));

    x1 = X(:, 1);
    x2 = X(:, 2);
    x3 = X(:, 3);

    switch basisType
        case "linear"
            Phi = [ones(size(X, 1), 1), X];

        case "nonlinear"
            pairwise = [x1 .* x2, x1 .* x3, x2 .* x3];
            squares = X .^ 2;

            thresholds = [];
            for threshold = [0.25, 0.50, 0.75]
                thresholds = [ ...
                    thresholds, ...
                    double(X >= threshold)]; %#ok<AGROW>
            end

            Phi = [ ...
                ones(size(X, 1), 1), ...
                X, ...
                squares, ...
                pairwise, ...
                thresholds];

        otherwise
            error("Unknown diagnostic basis: %s", basisType);
    end

end
