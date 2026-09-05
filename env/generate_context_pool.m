function contextPool = generate_context_pool(cfg)
%GENERATE_CONTEXT_POOL Generate independent context samples from G.
%
% The context distribution G is induced by the same wireless environment
% generator used in the simulation: Rayleigh fading, occupancy, noise,
% and delay model.
%
% Output:
%   contextPool - d x K x M tensor, where M = cfg.contextPoolSize

    cfgPool = cfg;
    cfgPool.T = cfg.contextPoolSize;

    envPool = generate_environment(cfgPool);

    contextPool = envPool.context;

end