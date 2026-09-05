function model = fit_diagnostic_ridge(X, y, basisType, lambda)
%FIT_DIAGNOSTIC_RIDGE Toolbox-free ridge regression.

    Phi = build_diagnostic_basis(X, basisType);
    penalty = eye(size(Phi, 2));
    penalty(1, 1) = 0;

    model.basisType = string(basisType);
    model.theta = (Phi' * Phi + lambda * penalty) \ (Phi' * y);
    model.lambda = lambda;

end
