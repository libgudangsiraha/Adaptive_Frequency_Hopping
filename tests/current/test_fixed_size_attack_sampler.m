clear; clc;

setup_paths();

rng(12345);

q = [0.30; 0.20; 0.15; 0.12; 0.08; 0.06; ...
     0.04; 0.025; 0.015; 0.01];
q = q / sum(q);
M = 3;
h = attack_inclusion_probability(q, M);

numSamples = 30000;
counts = zeros(numel(q), 1);

for sampleIndex = 1:numSamples
    jammed = sample_fixed_size_attack_set(h);
    assert(sum(jammed) == M);
    counts = counts + jammed;
end

empirical = counts / numSamples;
maxMarginalError = max(abs(empirical - h));

fprintf("Maximum marginal error: %.6f\n", maxMarginalError);
assert(maxMarginalError < 0.015);

%% Verify the policy-level expected hit identity.
pi = (1:numel(q))';
pi = pi / sum(pi);
expectedHit = pi' * h;

hitCount = 0;

for sampleIndex = 1:numSamples
    action = sample_categorical_local(pi);
    jammed = sample_fixed_size_attack_set(h);
    hitCount = hitCount + jammed(action);
end

empiricalHit = hitCount / numSamples;

fprintf("Expected hit: %.6f | empirical hit: %.6f\n", ...
    expectedHit, empiricalHit);

assert(abs(empiricalHit - expectedHit) < 0.015);

disp("Fixed-size attack sampler test passed.");


function index = sample_categorical_local(probability)

    index = find(rand <= cumsum(probability), 1, "first");

    if isempty(index)
        index = numel(probability);
    end

end
