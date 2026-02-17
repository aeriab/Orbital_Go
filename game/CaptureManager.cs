using Godot;
using System;
using System.Collections.Generic;
using Godot.Collections;

public partial class CaptureManager : Node2D
{
    private Node _global;
    private Node _stoneManager;

    [Export] public float CaptureCheckInterval = 0.2f;
    [Export] public float PointCheckInterval = 0.2f;

    [Export] public bool draw_debug_lines = false;
    [Export] public bool draw_debug_polygons = true;
    [Export] public float debug_alpha = 0.1f;

    private float _capture_timer = 0.0f;
    private float _point_timer = 0.0f;

    private List<(Vector2, Vector2)> _debugConnections = new List<(Vector2, Vector2)>();
    private List<(Vector2[], Color)> _debugPolygons = new List<(Vector2[], Color)>();

    public override void _Ready()
    {
        _global = GetNode("/root/Global");
        _stoneManager = GetNode("/root/StoneManager");
        ZIndex = 10;
    }

    public override void _PhysicsProcess(double delta)
    {
        _capture_timer += (float)delta;
        if (_capture_timer >= CaptureCheckInterval)
        {
            _capture_timer = 0.0f;
            RunCaptureLogic();
            QueueRedraw();
        }

        _point_timer += (float)delta;
        if (_point_timer >= PointCheckInterval)
        {
            _point_timer = 0.0f;
            UpdateTerritoryScore();
        }
    }

    public override void _Draw()
    {
        if (draw_debug_lines)
        {
            foreach (var connection in _debugConnections)
                DrawLine(ToLocal(connection.Item1), ToLocal(connection.Item2), Colors.Cyan, 1.0f);
        }

        if (draw_debug_polygons)
        {
            foreach (var polyData in _debugPolygons)
            {
                if (polyData.Item1.Length < 3) continue;
                Vector2[] localPoints = new Vector2[polyData.Item1.Length];
                for (int i = 0; i < polyData.Item1.Length; i++)
                    localPoints[i] = ToLocal(polyData.Item1[i]);
                DrawColoredPolygon(localPoints, polyData.Item2);
            }
        }
    }

    public void UpdateTerritoryScore()
    {
        var bodies = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        float zoneRadius = (float)_global.Get("zone_radius");
        float radiusSq = zoneRadius * zoneRadius;

        float p1Current = 0.0f;
        float p2Current = 0.5f;

        foreach (var body in bodies)
        {
            if (!IsInstanceValid(body)) continue;
            // Check the body itself AND its sub-stone children
            CheckNodeScore(body, radiusSq, ref p1Current, ref p2Current);
            foreach (Node child in body.GetChildren())
                if (child is Node2D child2D) CheckNodeScore(child2D, radiusSq, ref p1Current, ref p2Current);
        }

        _global.Set("p1_score", p1Current);
        _global.Set("p2_score", p2Current);
        _global.EmitSignal("score_updated", p1Current, p2Current);
    }

    private void CheckNodeScore(Node2D node, float radiusSq, ref float p1, ref float p2)
    {
        if (node.GlobalPosition.LengthSquared() <= radiusSq)
        {
            if (node.IsInGroup("P1")) p1 += 1;
            else if (node.IsInGroup("P2")) p2 += 1;
        }
    }

    private void RunCaptureLogic()
    {
        _debugConnections.Clear();
        _debugPolygons.Clear();
        DetectAndProcessCaptures("P1", "P2");
        DetectAndProcessCaptures("P2", "P1");
    }

    private void DetectAndProcessCaptures(string team, string opponent)
    {
        var allBodies = _stoneManager.Call("get_active_stones").AsGodotArray<RigidBody2D>();
        var teamNodes = new List<Node2D>();
        var opponentNodes = new List<Node2D>();

        // Gather all functional units (Bodies + Sub-Stones)
        foreach (var body in allBodies)
        {
            AddIfMatch(body, team, opponent, teamNodes, opponentNodes);
            foreach (Node child in body.GetChildren())
                if (child is Node2D child2D) AddIfMatch(child2D, team, opponent, teamNodes, opponentNodes);
        }

        if (teamNodes.Count < 3) return;

        var adj = BuildAdjacency(teamNodes);
        foreach (var kvp in adj)
            foreach (var neighbor in kvp.Value)
                _debugConnections.Add((kvp.Key.GlobalPosition, neighbor.GlobalPosition));

        var cycles = FindCycles(teamNodes, adj);
        var capturedNodes = new HashSet<Node2D>();
        Color polyColor = team == "P1" ? new Color(0.1f, 0.1f, 0.1f, debug_alpha) : new Color(0.9f, 0.9f, 0.9f, debug_alpha);

        foreach (var cycle in cycles)
        {
            Vector2[] polygon = new Vector2[cycle.Count];
            for (int i = 0; i < cycle.Count; i++) polygon[i] = cycle[i].GlobalPosition;

            _debugPolygons.Add((polygon, polyColor));

            foreach (var victim in opponentNodes)
            {
                var data = victim.Get("stone_data").As<Resource>();
                if (data != null && !(bool)data.Get("can_be_captured")) continue;

                if (Geometry2D.IsPointInPolygon(victim.GlobalPosition, polygon))
                    capturedNodes.Add(victim);
            }
        }

        foreach (var victim in capturedNodes)
            victim.Call("on_captured");
    }

    private void AddIfMatch(Node2D node, string team, string opponent, List<Node2D> teamList, List<Node2D> opponentList)
    {
        if (node.IsInGroup(team)) teamList.Add(node);
        else if (node.IsInGroup(opponent)) opponentList.Add(node);
    }

    private System.Collections.Generic.Dictionary<Node2D, List<Node2D>> BuildAdjacency(List<Node2D> nodes)
    {
        var adj = new System.Collections.Generic.Dictionary<Node2D, List<Node2D>>();
        var spaceState = GetViewport().GetWorld2D().DirectSpaceState;

        foreach (var n in nodes)
        {
            adj[n] = new List<Node2D>();
            CollisionShape2D shape = null;
            foreach (Node child in n.GetChildren()) if (child is CollisionShape2D cs) { shape = cs; break; }
            if (shape == null) continue;

            var query = new PhysicsShapeQueryParameters2D();
            query.Shape = shape.Shape;
            query.Transform = n.GlobalTransform;
            query.CollideWithAreas = false;
            query.CollideWithBodies = true;
            
            // Exclude parent body to prevent self-collision
            var parentBody = n is RigidBody2D rb ? rb : n.GetParent() as RigidBody2D;
            if (parentBody != null) query.Exclude = new Array<Rid> { parentBody.GetRid() };

            var results = spaceState.IntersectShape(query);
            foreach (Godot.Collections.Dictionary result in results)
            {
                var hit = result["collider"].As<RigidBody2D>();
                if (nodes.Contains(hit)) adj[n].Add(hit);
                foreach (Node child in hit.GetChildren())
                    if (child is Node2D c2D && nodes.Contains(c2D)) adj[n].Add(c2D);
            }
        }
        return adj;
    }

    private List<List<Node2D>> FindCycles(List<Node2D> nodes, System.Collections.Generic.Dictionary<Node2D, List<Node2D>> adj)
    {
        var cycles = new List<List<Node2D>>();
        var visited = new HashSet<Node2D>();

        foreach (var startNode in nodes)
        {
            if (visited.Contains(startNode)) continue;
            var parent = new System.Collections.Generic.Dictionary<Node2D, Node2D>();
            var stack = new Stack<Node2D>();
            stack.Push(startNode);

            while (stack.Count > 0)
            {
                var current = stack.Pop();
                if (!visited.Contains(current))
                {
                    visited.Add(current);
                    foreach (var neighbor in adj[current])
                    {
                        if (!visited.Contains(neighbor))
                        {
                            parent[neighbor] = current;
                            stack.Push(neighbor);
                        }
                        else if (parent.ContainsKey(current) && neighbor != parent[current])
                        {
                            var cycle = new List<Node2D> { neighbor, current };
                            var temp = current;
                            while (parent.ContainsKey(temp) && parent[temp] != neighbor)
                            {
                                temp = parent[temp];
                                cycle.Add(temp);
                            }
                            cycles.Add(cycle);
                        }
                    }
                }
            }
        }
        return cycles;
    }
}