# **cmake4vim**

I created this plugin in order to improve integration CMake to the Vim editor. I tried different plugins for vim which allow to work with cmake but I didn't find the plugin which was satisfied my requrements.

This plugin shows cmake results using quickfix list. If you installed **[vim-dispatch](https://github.com/tpope/vim-dispatch)** plugin, it will be use it, this means that if you are using vim with tmux, cmake output will be printed in a separate window. Also this plugin allow to specify cmake targets in order to avoid building of all project. 
If you want to generate a make command from cmake, you can use this plugin to set some flags for the make command (for example -jN and etc).

## **Installation**

You can use VimPlug for installation:
```vim
Plug 'ilyachur/cmake4vim'
```
Or Pathogen:
```sh
cd ~/.vim/bundle
git clone https://github.com/ilyachur/cmake4vim
```

## **Commands**

The current version of the plugin supports next commands:

 - **`:CMake`** creates a build directory (if it is necessary) and generates cmake project.
 - **`:CMakeResetAndReload`** removes cmake cache and re-generates cmake project.
 - **`:CMakeReset`** removes cmake cache (this command removes the cmake build directory).
 - **`:CMakeClean`** cleans the project (it is equal of the execution `make clean`).
 - **`:CMakeSelectTarget`** selects a target for project. You can put target name as a parameter for the command. If you don't put the target name as a parameter, plugin collects targets as a list and you will be able to choose target from this list.

## **Variables**

Plugin supports special global variables which are allow to change behaviour of commands (you can change them in your **.vimrc**):

 - **`g:cmake_build_dir`** allows to set cmake build directory. Default is empty. If variable is empty plugin uses **build** directory in the current folder.
 - **`g:cmake4vim_change_build_command`** if this variable is not equal 0, plugin will change the make command. Default is 1.
 - **`g:cmake_build_target`** set the target name for build. Default is empty. If variable is empty, plugin uses the **all** target for build.
 - **`g:make_arguments`** allows to set custom parameters for make command. Default is empty. If variable is empty, plugin launches `make` without arguments.
 - **`g:cmake_project_generator`** allows to set the project generator for build scripts. Default is empty.
 - **`g:cmake_install_prefix`** allows to change **`-DCMAKE_INSTALL_PREFIX`**. Default is empty.
 - **`g:cmake_build_type`** allows to change **`-DCMAKE_BUILD_TYPE`**. Default is empty.
 - **`g:cmake_c_compiler`** allows to change **`-DCMAKE_C_COMPILER`**. Default is empty.
 - **`g:cmake_cxx_compiler`** allows to change **`-DCMAKE_CXX_COMPILER`**. Default is empty.
 - **`g:cmake_usr_args`** allows to set user arguments for cmake. Default is empty.
