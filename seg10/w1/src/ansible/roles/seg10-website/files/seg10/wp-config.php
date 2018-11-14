<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'seg10');

/** MySQL database username */
define('DB_USER', 'seg10');

/** MySQL database password */
define('DB_PASSWORD', 'seg10');

/** MySQL hostname */
define('DB_HOST', '10.0.42.8');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8mb4');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'n*(DeKGwU_+WdY6cHC|yXb<8xc/+i[e<`c@iWJ1E ,g:yKX,)F|nDEGai6%jrbBS');
define('SECURE_AUTH_KEY',  'fyQ!.Sm_|YWGK4X#=JxaOT,?r`/0/mXQzR|r}5X0aO!R~^2e`816MJ>HF(9)VE$A');
define('LOGGED_IN_KEY',    'j-cn{g0h>);[lgw7/IaK^hCCmJQ]`z@_}nn#5vjTCbr;+|AIb?N/rv<TdXH[oouj');
define('NONCE_KEY',        'oke9QaWS&wU8ePY-haO_Gx,3wsB1P9~o>ocQv7W,I:`&Ez|@,5K- f*6(HY;lCDf');
define('AUTH_SALT',        '.mxnw^,//u}KaWl)k5|ol&q*Gs38&0>68D^zQ*muOQh}CF~dwXORN@sS`BcLYMCr');
define('SECURE_AUTH_SALT', '*]lkeJIPMh$MYBu|FyRustqTmY))Am:Uk:;1Aefry-_q9tH!slnlnR;iNu.d/azD');
define('LOGGED_IN_SALT',   '|+k::}_%yc?0C36N0}c`F>>/U[U9Ol pC3N}q6#*9`C+xR> E9Ll7w:d .Bhc}m~');
define('NONCE_SALT',       'o<s.ZQ4df%@n/DLzA9zZh@LS^T_3`xnC0!}3s4-(LSoeK(uK4yf&]NyVWu<p(6WS');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
