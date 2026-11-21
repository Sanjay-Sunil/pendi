export const THEME_COOKIE = "theme";

/**
 * Runs before first paint: applies the cookie theme, else the OS preference.
 * Dark is the default class on <html>, so this only ever removes it.
 */
export const themeScript = `(function(){try{var m=document.cookie.match(/(?:^|; )${THEME_COOKIE}=(light|dark)/);var t=m?m[1]:(window.matchMedia("(prefers-color-scheme: light)").matches?"light":"dark");if(t==="light")document.documentElement.classList.remove("dark");}catch(e){}})();`;
