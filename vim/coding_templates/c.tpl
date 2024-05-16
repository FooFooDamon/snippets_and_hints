/*
 * TODO: Brief description of this file.
 *
 * Copyright (c) ${YEAR} ${LCS_USER} <${LCS_EMAIL}>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

//#include "${SELF_HEADER}.h"

#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <stdio.h>
#include <getopt.h>
#include <assert.h>

#ifdef __cplusplus
extern "C" {
#endif

// Must be coincident with the copyright info at the beginning of this file.
#ifndef COPYRIGHT_STRING
#define COPYRIGHT_STRING                "Copyright (c) ${YEAR} ${LCS_USER} <${LCS_EMAIL}>\n" \
                                        "Licensed under the Apache License, Version 2.0"
#endif

#ifndef BRIEF_INTRO
#define BRIEF_INTRO                     "FIXME: Customize brief introduction of this program"
#endif

#ifndef USAGE_FORMAT
#define USAGE_FORMAT                    "[OPTION...] [FILE...]"
#endif

#define __CSTR(x)                       #x
#define CSTR(x)                         __CSTR(x)

#ifndef MAJOR_VER
#define MAJOR_VER                       0
#endif

#ifndef MINOR_VER
#define MINOR_VER                       1
#endif

#ifndef PATCH_VER
#define PATCH_VER                       0
#endif

#ifndef PRODUCT_VERSION
#define PRODUCT_VERSION                 CSTR(MAJOR_VER) "." CSTR(MINOR_VER) "." CSTR(PATCH_VER)
#endif

#ifndef __VER__
#define __VER__                         "<none>"
#endif

#define BIZ_TYPE_CANDIDATES             "normal,test"
#define BIZ_TYPE_DEFAULT                "normal"

#ifdef HAS_CONFIG_FILE
#ifndef DEFAULT_CONF_FILE
#define DEFAULT_CONF_FILE               "config.ini"
#endif
#endif

#ifdef HAS_LOGGER

#ifndef DEFAULT_LOG_FILE
#define DEFAULT_LOG_FILE                "unnamed.log"
#endif

#ifndef LOG_LEVEL_CANDIDATES
#define LOG_LEVEL_CANDIDATES            "debug,info,notice,warning,error,critical"
#endif

#ifndef LOG_LEVEL_DEFAULT
#define LOG_LEVEL_DEFAULT               "warning"
#endif

#endif // #ifdef HAS_LOGGER

typedef struct cmd_args
{
    int orphan_argc;
    const char **orphan_argv;
    const char *biz;
    const char *config_file;
#ifdef HAS_LOGGER
    const char *log_file;
    const char *log_level;
#else
    bool verbose;
    bool debug;
#endif
    // FIXME: Add more fields according to your need, and delete this comment line.
} cmd_args_t;

cmd_args_t parse_cmdline(int argc, char **argv)
{
    const struct
    {
        struct option content;
        const char* const description;
    } OPTION_RULES[] = {
        // name (long option), has_arg (no_*, required_* or optional_*), flag (fixed to NULL), val (short option or 0)
        // description string with proper \t and \n characters
        {
            { "help", no_argument, NULL, 'h' },
            "\t\tShow this help message."
        },
        {
            { "copyright", no_argument, NULL, 0 },
            "\tShow copyright info."
        },
        {
            { "version", no_argument, NULL, 'v' },
            "\t\tShow product version number."
        },
        {
            { "vcs-version", no_argument, NULL, 0 },
            "\tShow version number generated by version control system."
        },
#ifdef HAS_LOGGER
        {
            { "logfile", required_argument, NULL, 0 },
            " /PATH/TO/LOG/FILE\n\t\t\tSpecify log file. Default to " DEFAULT_LOG_FILE "."
        },
        {
            { "loglevel", required_argument, NULL, 0 },
            " {" LOG_LEVEL_CANDIDATES "}\n\t\t\tSpecify log level. Default to " LOG_LEVEL_DEFAULT "."
        },
#else
        {
            { "verbose", no_argument, NULL, 'V' },
            "\t\tRun in verbose mode to produce more messages."
        },
        {
            { "debug", no_argument, NULL, 0 },
            "\t\tProduce all messages of verbose mode, plus debug ones."
        },
#endif
#ifdef HAS_CONFIG_FILE
        {
            { "config", required_argument, NULL, 'c' },
            " /PATH/TO/CONFIG/FILE\n\t\t\tSpecify configuration file. Default to " DEFAULT_CONF_FILE "."
        },
#endif
        {
            { "biz", required_argument, NULL, 'b' },
            " {" BIZ_TYPE_CANDIDATES "}\n\t\t\tSpecify biz type. Default to " BIZ_TYPE_DEFAULT "."
        },
        // FIXME: Add more items according to your need, and delete this comment line.
    };
    struct option long_options[sizeof(OPTION_RULES) / sizeof(OPTION_RULES[0]) + 1];
    char short_options[(sizeof(OPTION_RULES) / sizeof(OPTION_RULES[0])) * 3] = { 0 };
    char *short_ptr = short_options;
    cmd_args_t result = {};
    size_t i;

#define abbr_map(long_name)             ({ \
    size_t _cnt; \
    int short_val = 0; \
    for (_cnt = 0; _cnt < sizeof(OPTION_RULES) / sizeof(OPTION_RULES[0]); ++_cnt) \
    { \
        if (0 == strcmp((long_name), OPTION_RULES[_cnt].content.name)) \
        { \
            short_val = OPTION_RULES[_cnt].content.val; \
            break; \
        } \
    } \
    short_val; \
})

    /*
     * NOTE: This block is part of fixed algorithm, DO NOT modify or delete it unless you have a better solution.
     */
    for (i = 0; i < sizeof(OPTION_RULES) / sizeof(OPTION_RULES[0]); ++i)
    {
        const struct option *opt = &OPTION_RULES[i].content;

        long_options[i] = *opt;

        if (opt->val <= 0)
            continue;

        *short_ptr++ = (char)opt->val;
        if (no_argument == opt->has_arg)
            continue;
        else if (required_argument == opt->has_arg)
            *short_ptr++ = ':';
        else
        {
            *short_ptr++ = ':';
            *short_ptr++ = ':';
        }
    }
    long_options[i] = (struct option){}; // sentinel

    /*
     * Set some default option values here.
     */
    result.biz = BIZ_TYPE_DEFAULT;
#ifdef HAS_CONFIG_FILE
    result.config_file = DEFAULT_CONF_FILE;
#endif
#ifdef HAS_LOGGER
    result.log_file = DEFAULT_LOG_FILE;
    result.log_level = LOG_LEVEL_DEFAULT;
#endif
    // FIXME: Add more settings according to your need, and delete this comment line.

    while (true)
    {
        int option_index = 0;
        int c = getopt_long(argc, argv, short_options, long_options, &option_index);

        if (-1 == c) // all parsed
            break;
        else if (0 == c)
            c = abbr_map(long_options[option_index].name); // re-mapped to short option and continue
        else
        {
            // empty block for the integrity of if-else statement
        } // continue as follows

        if (0 == c) // for long-only options
        {
            const char *long_opt = long_options[option_index].name;

            if (0 == strcmp(long_opt, "copyright"))
            {
                printf("%s\n", COPYRIGHT_STRING);
                exit(EXIT_SUCCESS);
            }
            else if (0 == strcmp(long_opt, "vcs-version"))
            {
                printf("%s\n", __VER__);
                exit(EXIT_SUCCESS);
            }
#ifdef HAS_LOGGER
            else if (0 == strcmp(long_opt, "logfile"))
                result.log_file = optarg;
            else if (0 == strcmp(long_opt, "loglevel"))
                result.log_level = optarg;
#else
            else if (0 == strcmp(long_opt, "debug"))
                result.debug = true;
#endif
            // FIXME: Add more branches according to your need, and delete this comment line.
            else
            {
                fprintf(stderr, "*** Are you forgetting to handle --%s option??\n", long_opt);
                exit(EINVAL);
            }
        } // c == 0: for long-only options
        else if (abbr_map("biz") == c)
            result.biz = optarg;
#ifdef HAS_CONFIG_FILE
        else if (abbr_map("config") == c)
            result.config_file = optarg;
#endif
        // FIXME: Add more branches according to your need, and delete this comment line.
        else if (abbr_map("help") == c) // NOTE: Branches below rarely need customizing.
        {
            const char *slash = strrchr(argv[0], '/');
            const char *program_name = (NULL == slash) ? argv[0] : (slash + 1);

            printf("\n%s - %s\n\nUsage: %s %s\n\n", program_name, BRIEF_INTRO, program_name, USAGE_FORMAT);
            for (i = 0; i < sizeof(OPTION_RULES) / sizeof(OPTION_RULES[0]); ++i)
            {
                const struct option *opt = &OPTION_RULES[i].content;
                bool has_short = (opt->val > 0);

                printf("  %c%c%c --%s%s\n\n", (has_short ? '-' : ' '), (has_short ? (char)opt->val : ' '),
                    (has_short ? ',' : ' '), opt->name, OPTION_RULES[i].description);
            }
            exit(EXIT_SUCCESS);
        }
        else if (abbr_map("version") == c)
        {
            printf("%s\n", PRODUCT_VERSION);
            exit(EXIT_SUCCESS);
        }
#ifndef HAS_LOGGER
        else if (abbr_map("verbose") == c)
            result.verbose = true;
#endif
        else if ('?' == c || ':' == c)
            exit(EINVAL); // getopt_long() will print the reason.
        else // This case should never happen.
        {
            fprintf(stderr, "?? getopt returned character code 0%o ??\n", c);
            exit(EINVAL);
        }
    } // while (true)

    result.orphan_argc = (argc > optind) ? (argc - optind) : 0;
    result.orphan_argv = (argc > optind) ? (const char **)&argv[optind] : NULL;
    // FIXME: Decide how to use orphan_argv, and delete this comment line.

    return result;
} // cmd_args_t parse_cmdline(int argc, char **argv)

#undef CSTR

static void assert_parsed_args(const cmd_args_t *args)
{
    const struct
    {
        const char *name;
        const char *val;
    } *req_arg, required_str_args[] = {
        { "biz type", args->biz },
#ifdef HAS_CONFIG_FILE
        { "config file", args->config_file },
#endif
#ifdef HAS_LOGGER
        { "log file", args->log_file },
        { "log level", args->log_level },
#endif
        // FIXME: Add more items according to your need, and delete this comment line.
    };
    const struct
    {
        const char *name;
        const char *val;
        const char *candidates;
    } *enum_arg, enum_str_args[] = {
        { "biz type", args->biz, BIZ_TYPE_CANDIDATES },
#ifdef HAS_LOGGER
        { "log level", args->log_level, LOG_LEVEL_CANDIDATES },
#endif
        // FIXME: Add more items according to your need, and delete this comment line.
    };
    size_t i;

    for (i = 0; i < sizeof(required_str_args) / sizeof(required_str_args[0]); ++i)
    {
        req_arg = &required_str_args[i];
        if (NULL == req_arg->val || '\0' == req_arg->val[0])
        {
            fprintf(stderr, "*** %s is null or not specified!\n", req_arg->name);
            exit(EINVAL);
        }
    }

    for (i = 0; i < sizeof(enum_str_args) / sizeof(enum_str_args[0]); ++i)
    {
        const char *ptr;
        size_t len;

        enum_arg = &enum_str_args[i];
        ptr = (enum_arg->val && enum_arg->val[0]) ? strstr(enum_arg->candidates, enum_arg->val) : NULL;
        len = ptr ? strlen(enum_arg->val) : 0;

        if (NULL == ptr || (',' != ptr[len] && '\0' != ptr[len]))
        {
            fprintf(stderr, "*** Invalid %s: %s\nMust be one of {%s}\n",
                enum_arg->name, enum_arg->val, enum_arg->candidates);
            exit(EINVAL);
        }
    }

    // FIXME: Add more validations according to your need, and delete this comment line.
} // void assert_parsed_args(const cmd_args_t *args)

#define todo()                          fprintf(stderr, __FILE__ ":%d %s(): todo ...\n", __LINE__, __func__)

typedef struct conf_file
{
    const char *path;
    // Add more fields according to your need, and delete this comment line.
} conf_file_t;

int load_config_file(const char *path, conf_file_t *result)
{
#ifdef HAS_CONFIG_FILE
    todo();
#endif
    return 0;
}

void unload_config_file(conf_file_t *result)
{
#ifdef HAS_CONFIG_FILE
    todo();
#endif
}

int logger_init(const cmd_args_t *args, const conf_file_t *conf)
{
#ifdef HAS_LOGGER
    todo();
#endif
    return 0;
}

void logger_finalize(void)
{
#ifdef HAS_LOGGER
    todo();
#endif
}

int register_signals(const cmd_args_t *args, const conf_file_t *conf)
{
#ifdef NEED_OS_SIGNALS
    todo();
#endif
    return 0;
}

#define BIZ_FUN_ARG_LIST                int argc, char **argv, const cmd_args_t *parsed_args, const conf_file_t *conf
#define DECLARE_BIZ_FUN(name)           int name(BIZ_FUN_ARG_LIST)
#define BIZ_FUN(name)                   name
typedef int (*biz_func_t)(BIZ_FUN_ARG_LIST);

static DECLARE_BIZ_FUN(normal_biz)
{
    todo();

    return EXIT_SUCCESS;
}

static DECLARE_BIZ_FUN(test_biz)
{
    todo();

    return EXIT_SUCCESS;
}

int main(int argc, char **argv)
{
    cmd_args_t parsed_args = parse_cmdline(argc, argv);
    conf_file_t conf;
    struct
    {
        const char *name;
        biz_func_t func;
    } biz_handlers[] = {
        { "normal", BIZ_FUN(normal_biz) },
        { "test", BIZ_FUN(test_biz) },
    };
    size_t i;
    biz_func_t biz_func = NULL;
    int ret;

    assert_parsed_args(&parsed_args);

    for (i = 0; i < sizeof(biz_handlers) / sizeof(biz_handlers[0]); ++i)
    {
        if (0 == strcmp(parsed_args.biz, biz_handlers[i].name))
        {
            biz_func = biz_handlers[i].func;
            break;
        }
    }
    if (NULL == biz_func)
    {
        fprintf(stderr, "*** Biz[%s] is not supported yet!\n", parsed_args.biz);
        return ENOTSUP;
    }

    if ((ret = load_config_file(parsed_args.config_file, &conf)) < 0)
        return -ret;

    if ((ret = logger_init(&parsed_args, &conf)) < 0)
        goto lbl_unload_conf;

    if ((ret = register_signals(&parsed_args, &conf)) < 0)
        goto lbl_finalize_log;

    ret = biz_func(argc, argv, &parsed_args, &conf);

lbl_finalize_log:
    logger_finalize();

lbl_unload_conf:
    unload_config_file(&conf);

    return abs(ret);
}

#ifdef __cplusplus
}
#endif

/*
 * ================
 *   CHANGE LOG
 * ================
 *
 * >>> ${DATE}, ${LCS_USER} <${LCS_EMAIL}>:
 *  01. Create.
 */
