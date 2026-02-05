# AGENTS.md

## Instructions for AI Agents

You are a professional Godot developer. When generating or modifying code for this project, you MUST adhere to the following requirements:

- **Language:** Use only GDScript, targeting Godot 4.x (preferably 4.4+).
- **Code Quality:** Write clean, idiomatic, and maintainable code that follows the [official Godot GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Best Practices:**  
  - Use type hints and static typing where possible.
  - Prefer `@export` for editor-exposed variables.
  - Use signals for decoupled communication between nodes.
  - Structure scripts for readability: group related functions, use clear naming, and add concise docstrings.
  - Avoid deprecated methods and features.
  - Max line length is 100
- **Scene Structure:**  
  - Organize nodes logically.
  - Use `_ready()`, `_process(delta)`, and other Godot lifecycle methods appropriately.
- **Comments:**  
  - Add comments where necessary to explain complex logic, but avoid redundant comments.
  - Function comments should look like this (@-Tags are optional, only add them if needed!):
     ```
    extends Node2D
    ## A brief description of the class's role and functionality.
    ##
    ## The description of the script, what it can do,
    ## and any further detail.
    ##
    ## @tutorial:             https://example.com/tutorial_1
    ## @tutorial(Tutorial 2): https://example.com/tutorial_2
    ## @experimental

    ## The description of a signal.
    signal my_signal

    ## This is a description of the below enum.
    enum Direction {
      ## Direction up.
      UP = 0,
      ## Direction down.
      DOWN = 1,
      ## Direction left.
      LEFT = 2,
      ## Direction right.
      RIGHT = 3,
    }

    ## The description of a constant.
    const GRAVITY = 9.8

    ## The description of the variable v1.
    var v1

    ## This is a multiline description of the variable v2.[br]
    ## The type information below will be extracted for the documentation.
    var v2: int

    ## If the member has any annotation, the annotation should
    ## immediately precede it.
    @export
    var v3 := some_func()


    ## As the following function is documented, even though its name starts with
    ## an underscore, it will appear in the help window.
    func _fn(p1: int, p2: String) -> int:
      return 0


    # The below function isn't documented and its name starts with an underscore
    # so it will treated as private and will not be shown in the help window.
    func _internal() -> void:
      pass


    ## Documenting an inner class.
    ##
    ## The same rules apply here. The documentation must
    ## immediately precede the class definition.
    ##
    ## @tutorial: https://example.com/tutorial
    ## @experimental
    class Inner:

      ## Inner class variable v4.
      var v4


      ## Inner class function fn.
      func fn(): pass
    ```
- **File Organization:**  
  - Place scripts in relevant directories: 
    - Scenes in ./Scenes
    - Scripts in ./Scripts
  - Name files and classes clearly and consistently.

**Remember:**  
All code contributions must reflect the standards and expectations of a professional Godot developer working with Godot 4.x.
