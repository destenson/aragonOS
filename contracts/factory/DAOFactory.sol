pragma solidity 0.4.18;

import "../kernel/Kernel.sol";
import "../kernel/KernelProxy.sol";

import "./AppProxyFactory.sol";
import "./EVMScriptRegistryFactory.sol";

contract DAOFactory is AppProxyFactory {
    address public baseKernel;
    EVMScriptRegistryFactory public regFactory;

    function DAOFactory(address _regFactory) public {
        // No need to init as it cannot be killed by devops199
        baseKernel = address(new Kernel());

        if (_regFactory != address(0)) {
            regFactory = EVMScriptRegistryFactory(_regFactory);
        }
    }

    /**
    * @param _root Address that will be granted control to setup DAO permissions
    */
    function newDAO(address _root) public returns (Kernel dao) {
        dao = Kernel(new KernelProxy(baseKernel));
        address initialRoot = address(regFactory) != address(0) ? this : _root;
        dao.initialize(initialRoot);

        if (address(regFactory) != address(0)) {
            dao.grantPermission(regFactory, dao, dao.CREATE_PERMISSIONS_ROLE());
            dao.createPermission(regFactory, dao, dao.UPGRADE_APPS_ROLE(), this);
            dao.createPermission(regFactory, dao, dao.SET_APP_ROLE(), this);

            regFactory.newEVMScriptRegistry(dao, _root);

            dao.revokePermission(regFactory, dao, dao.UPGRADE_APPS_ROLE());
            dao.revokePermission(regFactory, dao, dao.SET_APP_ROLE());

            dao.setPermissionManager(address(0), dao, dao.UPGRADE_APPS_ROLE());
            dao.setPermissionManager(address(0), dao, dao.SET_APP_ROLE());

            dao.setPermissionManager(_root, dao, dao.CREATE_PERMISSIONS_ROLE());
        }
    }
}