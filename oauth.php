<?php
/*
 *  Jirafeau, your web file repository
 *  Copyright (C) 2013
 *  Jerome Jutteau <jerome@jutteau.fr>
 *  Jimmy Beauvois <jimmy.beauvois@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
require(__DIR__ . '/vendor/autoload.php');
session_start();
define('JIRAFEAU_ROOT', dirname(__FILE__) . '/');

require(JIRAFEAU_ROOT . 'lib/settings.php');
require(JIRAFEAU_ROOT . 'lib/functions.php');
require(JIRAFEAU_ROOT . 'lib/lang.php');

check_errors($cfg);
if (has_error()) {
    show_errors();
    require(JIRAFEAU_ROOT . 'lib/template/footer.php');
    exit;
}

// Second check: Challenge by IP
if (!isset($_GET['state']) || !isset($_GET['code'])) {
    echo jirafeau_do_oauth_level_1($cfg);
    exit;
}

echo jirafeau_do_oauth_level_2($cfg, $_GET['state'], $_GET['code']);
exit;
?>
