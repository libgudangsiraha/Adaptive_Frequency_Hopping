%VERIFY_RELEASE Fast non-destructive unit verification for the public release.
clear functions
rehash
setup_paths

tests = {
    'tests/current/test_attack_inclusion_probability_exact.m'
    'tests/current/test_dynamic_pact_exact.m'
    'tests/current/test_kl_hit_risk_projection_exact.m'
    'tests/current/test_reward_alignment_v2.m'
    'tests/current/test_fixed_size_attack_sampler.m'
    'tests/current/test_hybrid_expert_bank_v2.m'
};

for i = 1:numel(tests)
    fprintf('[TEST] %s\n', tests{i});
    run(tests{i});
end

disp('MATLAB_RELEASE_TESTS_PASS');
