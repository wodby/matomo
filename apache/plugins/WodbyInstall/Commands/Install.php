<?php

namespace Piwik\Plugins\WodbyInstall\Commands;

use Piwik\Access;
use Piwik\Config;
use Piwik\DbHelper;
use Piwik\Plugin\ConsoleCommand;
use Piwik\Plugin\Manager;
use Piwik\Plugins\Installation\ServerFilesGenerator;
use Piwik\Plugins\SitesManager\API as APISitesManager;
use Piwik\Plugins\UsersManager\API as APIUsersManager;
use Piwik\Plugins\UsersManager\UserUpdater;
use Piwik\Updater;
use Piwik\Version;

/**
 * Installs Matomo into an empty database the way the web installer does, with
 * the superuser and first website taken from the environment rather than from
 * the command line, so no password appears in a process list:
 * MATOMO_ADMIN_USERNAME (default admin), MATOMO_ADMIN_PASSWORD,
 * MATOMO_ADMIN_EMAIL, MATOMO_SITE_NAME and MATOMO_SITE_URL.
 *
 * The database, salt and trusted hosts come from config/common.config.ini.php.
 * A database that already has tables is never installed into.
 */
class Install extends ConsoleCommand
{
    protected function configure()
    {
        $this->setName('wodby:install');
        $this->setDescription('Install Matomo with settings from the environment');
    }

    protected function doExecute(): int
    {
        $output = $this->getOutput();

        $login = getenv('MATOMO_ADMIN_USERNAME') ?: 'admin';
        $password = getenv('MATOMO_ADMIN_PASSWORD') ?: '';
        $email = getenv('MATOMO_ADMIN_EMAIL') ?: '';
        $siteName = getenv('MATOMO_SITE_NAME') ?: 'Matomo';
        $siteUrl = getenv('MATOMO_SITE_URL') ?: '';

        if ($password === '' || $email === '') {
            $output->writeln('<error>Set MATOMO_ADMIN_PASSWORD and MATOMO_ADMIN_EMAIL to install Matomo.</error>');
            return self::FAILURE;
        }

        if (count(DbHelper::getTablesInstalled()) > 0) {
            $output->writeln('<error>The database already has tables. Matomo is installed only into an empty database.</error>');
            return self::FAILURE;
        }

        // The local settings file exists from here on, marked as an installation
        // in progress, so an interrupted run never counts as installed.
        $config = Config::getInstance();
        $config->General['installation_in_progress'] = 1;
        $config->forceSave();

        $output->writeln('Creating tables...');
        DbHelper::createTables();
        DbHelper::createAnonymousUser();
        DbHelper::recordInstallVersion();
        Access::doAsSuperUser(function () {
            $updater = new Updater();
            $components = $updater->getComponentUpdates();
            if (!empty($components)) {
                $updater->updateComponents($components);
            }
        });
        Updater::recordComponentSuccessfullyUpdated('core', Version::VERSION);
        Manager::getInstance()->installLoadedPlugins();

        ServerFilesGenerator::createFilesForSecurity();

        $output->writeln(sprintf('Creating the superuser %s...', $login));
        Access::doAsSuperUser(function () use ($login, $password, $email) {
            APIUsersManager::getInstance()->addUser($login, $password, $email);
            (new UserUpdater())->setSuperUserAccessWithoutCurrentPassword($login, true);
        });

        if ($siteUrl !== '') {
            $output->writeln(sprintf('Adding the website %s...', $siteName));
            Access::doAsSuperUser(function () use ($siteName, $siteUrl) {
                APISitesManager::getInstance()->addSite($siteName, [$siteUrl]);
            });
        }

        unset($config->General['installation_in_progress']);
        unset($config->General['installation_first_accessed']);
        $config->forceSave();

        $output->writeln('<info>Matomo is installed.</info>');

        return self::SUCCESS;
    }
}
