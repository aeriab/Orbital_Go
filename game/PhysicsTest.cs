using Godot;
using System;

public partial class PhysicsTest : Node2D
{
    public override void _PhysicsProcess(double delta)
    {
        // We only run this when the mouse is clicked to avoid console spam
        if (Input.IsActionJustPressed("ui_accept")) // Default "Enter/Space"
        {
            RunPhysicsQuery();
        }
    }

    private void RunPhysicsQuery()
    {
        // 1. Get the Direct Space State (The 'Brain' of the physics world)
        var spaceState = GetWorld2D().DirectSpaceState;

        // 2. Set up the query parameters
        // We are checking a single point (the mouse position)
        var query = new PhysicsPointQueryParameters2D();
        query.Position = GetGlobalMousePosition();
        query.CollideWithAreas = true; // Set to true to detect your Stone Area2Ds
        query.CollisionMask = 1;      // Only look at Layer 1

        // 3. Execute the query
        // This returns an array of dictionaries containing metadata about hits
        var results = spaceState.IntersectPoint(query);

        if (results.Count > 0)
        {
            GD.Print($"Found {results.Count} objects at {query.Position}");
            
            foreach (var hit in results)
            {
                // Each 'hit' is a Dictionary. 'collider' is the actual Node object.
                var collider = hit["collider"].As<Node2D>();
                GD.Print($"- Hit: {collider.Name} (RID: {hit["rid"]})");
            }
        }
        else
        {
            GD.Print("Space is empty at: " + query.Position);
        }
    }
}